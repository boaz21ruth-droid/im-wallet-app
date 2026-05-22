import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'chain_config.dart';
import 'wallet_models.dart';

const _erc20TransferAbi = '''[
  {"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"type":"function"},
  {"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"type":"function"}
]''';

class EvmService {
  final ChainConfig config;
  final String chainKey;

  // One Web3Client per RPC URL, created upfront
  late final List<Web3Client> _clients;

  // Index of the last RPC that successfully responded — sticky within this instance
  int _preferred = 0;

  EvmService(this.config, this.chainKey)
      : _clients = config.rpcs
            .map((url) => Web3Client(url, http.Client()))
            .toList();

  // Core retry wrapper: starts at _preferred, rotates on any exception.
  // On success, pins _preferred to that index so subsequent calls in the
  // same session skip already-failed nodes.
  Future<T> _rpc<T>(Future<T> Function(Web3Client c) fn) async {
    Object? lastError;
    for (var offset = 0; offset < _clients.length; offset++) {
      final idx = (_preferred + offset) % _clients.length;
      try {
        final result = await fn(_clients[idx]);
        _preferred = idx;
        return result;
      } catch (e) {
        lastError = e;
        // Continue to next node
      }
    }
    throw lastError!;
  }

  // ── Read operations ───────────────────────────────────────────────────────

  Future<BigInt> getNativeBalance(String address) async {
    final addr = EthereumAddress.fromHex(address);
    final bal = await _rpc((c) => c.getBalance(addr));
    return bal.getInWei;
  }

  Future<BigInt> getTokenBalance(String walletAddress, String contractAddress) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20TransferAbi, 'ERC20'),
      EthereumAddress.fromHex(contractAddress),
    );
    final fn = contract.function('balanceOf');
    final result = await _rpc(
      (c) => c.call(
        contract: contract,
        function: fn,
        params: [EthereumAddress.fromHex(walletAddress)],
      ),
    );
    return result.first as BigInt;
  }

  Future<List<AssetBalance>> getAllBalances(String address) async {
    final balances = <AssetBalance>[];
    final native = await getNativeBalance(address);
    balances.add(AssetBalance(
      chainKey: chainKey,
      symbol: config.symbol,
      rawBalance: native,
      decimals: config.decimals,
    ));
    for (final token in config.builtinTokens) {
      try {
        final raw = await getTokenBalance(address, token.contractAddress);
        balances.add(AssetBalance(
          chainKey: chainKey,
          symbol: token.symbol,
          rawBalance: raw,
          decimals: token.decimals,
          contractAddress: token.contractAddress,
        ));
      } catch (_) {
        balances.add(AssetBalance(
          chainKey: chainKey,
          symbol: token.symbol,
          rawBalance: BigInt.zero,
          decimals: token.decimals,
          contractAddress: token.contractAddress,
        ));
      }
    }
    return balances;
  }

  Future<BigInt> estimateTransferGas({
    required String from,
    required String to,
    required BigInt value,
    Uint8List? data,
  }) async {
    return _rpc(
      (c) => c.estimateGas(
        sender: EthereumAddress.fromHex(from),
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.fromBigInt(EtherUnit.wei, value),
        data: data,
      ),
    );
  }

  Future<BigInt> getGasPrice() async {
    final gp = await _rpc((c) => c.getGasPrice());
    return gp.getInWei;
  }

  // ── Write operations (send via same retry wrapper) ────────────────────────

  Future<String> sendNative({
    required EthPrivateKey senderKey,
    required String to,
    required BigInt value,
    int? gasLimit,
  }) async {
    return _rpc((c) async {
      final gasPrice = await c.getGasPrice();
      final tx = Transaction(
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.fromBigInt(EtherUnit.wei, value),
        gasPrice: gasPrice,
        maxGas: gasLimit ?? 21000,
      );
      return c.sendTransaction(senderKey, tx, chainId: config.chainId);
    });
  }

  Future<String> sendToken({
    required EthPrivateKey senderKey,
    required String tokenContract,
    required String to,
    required BigInt amount,
    int? gasLimit,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(_erc20TransferAbi, 'ERC20'),
      EthereumAddress.fromHex(tokenContract),
    );
    final fn = contract.function('transfer');
    return _rpc((c) async {
      final gasPrice = await c.getGasPrice();
      final tx = Transaction.callContract(
        contract: contract,
        function: fn,
        parameters: [EthereumAddress.fromHex(to), amount],
        gasPrice: gasPrice,
        maxGas: gasLimit ?? 100000,
      );
      return c.sendTransaction(senderKey, tx, chainId: config.chainId);
    });
  }

  // ── Transaction history (Explorer API, not RPC) ───────────────────────────

  Future<List<TxRecord>> getTransactionHistory(
    String address, {
    int page = 1,
    int offset = 20,
  }) async {
    final url = Uri.parse(
      '${config.explorer}?module=account&action=txlist'
      '&address=$address&startblock=0&endblock=99999999'
      '&page=$page&offset=$offset&sort=desc',
    );
    try {
      final resp = await http.get(url);
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = json['result'] as List? ?? [];
      return result.map((e) {
        final m = e as Map<String, dynamic>;
        final value = BigInt.tryParse(m['value'] as String? ?? '0') ?? BigInt.zero;
        final ts = int.tryParse(m['timeStamp'] as String? ?? '0') ?? 0;
        return TxRecord(
          hash: m['hash'] as String? ?? '',
          from: m['from'] as String? ?? '',
          to: m['to'] as String? ?? '',
          value: value,
          decimals: config.decimals,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
          status: m['isError'] == '1' ? 'failed' : 'confirmed',
          chainKey: chainKey,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    for (final c in _clients) {
      c.dispose();
    }
  }
}
