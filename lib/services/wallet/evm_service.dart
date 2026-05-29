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

  // Raw JSON-RPC helper — uses config.rpcs with same retry strategy as _rpc()
  Future<dynamic> _jsonRpc(String method, List<dynamic> params) async {
    Object? lastError;
    for (var offset = 0; offset < config.rpcs.length; offset++) {
      final idx = (_preferred + offset) % config.rpcs.length;
      try {
        final resp = await http.post(
          Uri.parse(config.rpcs[idx]),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': params, 'id': 1}),
        );
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        if (body.containsKey('error')) throw Exception(body['error']);
        _preferred = idx;
        return body['result'];
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError!;
  }

  // Uses eth_getLogs — no Explorer API key required.
  Future<List<TxRecord>> getErc20TransferHistory(
    String address,
    String contractAddress, {
    int limit = 20,
  }) async {
    // keccak256("Transfer(address,address,uint256)")
    const transferTopic = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';
    final addrPadded = '0x000000000000000000000000${address.replaceFirst('0x', '').toLowerCase()}';

    try {
      final blockHex = await _jsonRpc('eth_blockNumber', []) as String;
      final current = int.parse(blockHex.replaceFirst('0x', ''), radix: 16);

      // Scan backwards in 2000-block chunks (safe for all public RPCs).
      // Stop once we have enough results or cover ~50k blocks.
      const chunkSize = 2000;
      const maxChunks = 25;
      final seen = <String>{};
      final all = <Map<String, dynamic>>[];

      for (var i = 0; i < maxChunks && all.length < limit; i++) {
        final toBlock = current - i * chunkSize;
        if (toBlock < 0) break;
        final fromBlock = (toBlock - chunkSize + 1).clamp(0, toBlock);
        final fromHex = '0x${fromBlock.toRadixString(16)}';
        final toHex = '0x${toBlock.toRadixString(16)}';
        try {
          final results = await Future.wait([
            _jsonRpc('eth_getLogs', [{'address': contractAddress, 'topics': [transferTopic, addrPadded], 'fromBlock': fromHex, 'toBlock': toHex}]),
            _jsonRpc('eth_getLogs', [{'address': contractAddress, 'topics': [transferTopic, null, addrPadded], 'fromBlock': fromHex, 'toBlock': toHex}]),
          ]);
          for (final log in [
            ...(results[0] as List? ?? []).cast<Map<String, dynamic>>(),
            ...(results[1] as List? ?? []).cast<Map<String, dynamic>>(),
          ]) {
            if (seen.add(log['transactionHash'] as String? ?? '')) all.add(log);
          }
        } catch (_) {
          continue;
        }
      }

      all.sort((a, b) {
        final ba = int.tryParse(((a['blockNumber'] as String?) ?? '0x0').replaceFirst('0x', ''), radix: 16) ?? 0;
        final bb = int.tryParse(((b['blockNumber'] as String?) ?? '0x0').replaceFirst('0x', ''), radix: 16) ?? 0;
        return bb.compareTo(ba);
      });
      final trimmed = all.take(limit).toList();

      // Fetch timestamps by unique block number
      final blockHexes = trimmed.map((e) => e['blockNumber'] as String?).whereType<String>().toSet();
      final timestamps = <String, int>{};
      await Future.wait(blockHexes.map((hex) async {
        try {
          final block = await _jsonRpc('eth_getBlockByNumber', [hex, false]) as Map<String, dynamic>?;
          final ts = block?['timestamp'] as String?;
          if (ts != null) timestamps[hex] = int.parse(ts.replaceFirst('0x', ''), radix: 16);
        } catch (_) {}
      }));

      BuiltinToken? tokenInfo;
      for (final t in config.builtinTokens) {
        if (t.contractAddress.toLowerCase() == contractAddress.toLowerCase()) {
          tokenInfo = t;
          break;
        }
      }
      final tokenDecimals = tokenInfo?.decimals ?? 18;

      return trimmed.map((log) {
        final topics = (log['topics'] as List? ?? []).cast<String>();
        final from = topics.length > 1 ? '0x${topics[1].replaceFirst('0x', '').substring(24)}' : '';
        final to   = topics.length > 2 ? '0x${topics[2].replaceFirst('0x', '').substring(24)}' : '';
        final data = log['data'] as String? ?? '0x';
        final value = data.length > 2
            ? BigInt.tryParse(data.replaceFirst('0x', ''), radix: 16) ?? BigInt.zero
            : BigInt.zero;
        final blockHex = log['blockNumber'] as String? ?? '0x0';
        final ts = timestamps[blockHex] ?? 0;
        return TxRecord(
          hash: log['transactionHash'] as String? ?? '',
          from: from,
          to: to,
          value: value,
          decimals: tokenDecimals,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
          status: 'confirmed',
          chainKey: chainKey,
          tokenContract: contractAddress,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Swap helpers ──────────────────────────────────────────────────────────

  /// ERC20 `decimals()` selector: 0x313ce567.
  Future<int> getDecimals(String contractAddress) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(
          '[{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"type":"function"}]',
          'ERC20Decimals'),
      EthereumAddress.fromHex(contractAddress),
    );
    final fn = contract.function('decimals');
    final result = await _rpc(
      (c) => c.call(contract: contract, function: fn, params: []),
    );
    return (result.first as BigInt).toInt();
  }

  Future<BigInt> getAllowance({
    required String owner,
    required String spender,
    required String tokenContract,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(
          '[{"constant":true,"inputs":[{"name":"o","type":"address"},{"name":"s","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"type":"function"}]',
          'ERC20Allowance'),
      EthereumAddress.fromHex(tokenContract),
    );
    final fn = contract.function('allowance');
    final result = await _rpc(
      (c) => c.call(
        contract: contract,
        function: fn,
        params: [
          EthereumAddress.fromHex(owner),
          EthereumAddress.fromHex(spender),
        ],
      ),
    );
    return result.first as BigInt;
  }

  /// Approves `spender` to spend `amount` of `tokenContract`. Returns tx hash.
  /// For swap flows callers should pass MaxUint256.
  Future<String> sendApprove({
    required EthPrivateKey senderKey,
    required String tokenContract,
    required String spender,
    required BigInt amount,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(
          '[{"inputs":[{"name":"_s","type":"address"},{"name":"_v","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"type":"function"}]',
          'ERC20Approve'),
      EthereumAddress.fromHex(tokenContract),
    );
    final fn = contract.function('approve');
    return _rpc((c) async {
      final gasPrice = await c.getGasPrice();
      final tx = Transaction.callContract(
        contract: contract,
        function: fn,
        parameters: [EthereumAddress.fromHex(spender), amount],
        gasPrice: gasPrice,
        maxGas: 70000,
      );
      return c.sendTransaction(senderKey, tx, chainId: config.chainId);
    });
  }

  /// Broadcasts an arbitrary calldata transaction (e.g. 0x swap calldata).
  /// `dataHex` may or may not start with "0x".
  Future<String> sendRaw({
    required EthPrivateKey senderKey,
    required String to,
    required String dataHex,
    required BigInt value,
    BigInt? gasLimit,
    BigInt? gasPrice,
  }) async {
    final hex = dataHex.startsWith('0x') ? dataHex.substring(2) : dataHex;
    final bytes = Uint8List.fromList(
      [for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)],
    );
    return _rpc((c) async {
      final BigInt gp;
      if (gasPrice != null) {
        gp = gasPrice;
      } else {
        final fetched = await c.getGasPrice();
        gp = fetched.getInWei;
      }
      final tx = Transaction(
        to: EthereumAddress.fromHex(to),
        value: EtherAmount.fromBigInt(EtherUnit.wei, value),
        data: bytes,
        gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, gp),
        maxGas: gasLimit?.toInt() ?? 300000,
      );
      return c.sendTransaction(senderKey, tx, chainId: config.chainId);
    });
  }

  /// Polls receipt until status is known or timeout. Returns true iff status==1.
  Future<bool> waitForReceipt(String txHash, {Duration timeout = const Duration(seconds: 60)}) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      try {
        final receipt = await _rpc((c) => c.getTransactionReceipt(txHash));
        if (receipt != null) {
          return receipt.status == true;
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
    return false;
  }

  void dispose() {
    for (final c in _clients) {
      c.dispose();
    }
  }
}
