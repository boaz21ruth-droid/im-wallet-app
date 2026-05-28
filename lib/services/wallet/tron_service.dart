import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart' as w3c;
import 'chain_config.dart';
import 'wallet_models.dart';

class TronService {
  final String chainKey;
  late final List<Dio> _clients;
  int _preferred = 0;

  TronService({this.chainKey = 'tron'}) {
    final rpcs = chains[chainKey]!.rpcs;
    _clients = rpcs
        .map(
          (base) => Dio(BaseOptions(
            baseUrl: base,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          )),
        )
        .toList();
  }

  // Retry across all nodes; pins _preferred on success
  Future<Response<T>> _get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    Object? lastError;
    for (var offset = 0; offset < _clients.length; offset++) {
      final idx = (_preferred + offset) % _clients.length;
      try {
        final resp = await _clients[idx].get<T>(path, queryParameters: queryParameters);
        _preferred = idx;
        return resp;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError!;
  }

  Future<Response<T>> _post<T>(String path, {dynamic data}) async {
    Object? lastError;
    for (var offset = 0; offset < _clients.length; offset++) {
      final idx = (_preferred + offset) % _clients.length;
      try {
        final resp = await _clients[idx].post<T>(path, data: data);
        _preferred = idx;
        return resp;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError!;
  }

  // ── Read operations ───────────────────────────────────────────────────────

  Future<BigInt> getTrxBalance(String tronAddress) async {
    try {
      final resp = await _get<Map<String, dynamic>>('/v1/accounts/$tronAddress');
      final data = resp.data ?? {};
      return BigInt.from(data['balance'] as int? ?? 0);
    } catch (_) {
      return BigInt.zero;
    }
  }

  Future<BigInt> getTrc20Balance(String tronAddress, String contractAddress) async {
    try {
      final resp = await _get<Map<String, dynamic>>(
        '/v1/accounts/$tronAddress/tokens',
        queryParameters: {'contract_address': contractAddress, 'only_confirmed': true},
      );
      final data = resp.data ?? {};
      final list = data['data'] as List? ?? [];
      if (list.isEmpty) return BigInt.zero;
      final balance = (list.first as Map<String, dynamic>)['balance'];
      return BigInt.tryParse(balance?.toString() ?? '0') ?? BigInt.zero;
    } catch (_) {
      return BigInt.zero;
    }
  }

  Future<List<AssetBalance>> getAllBalances(String address) async {
    final cfg = chains[chainKey]!;
    final nativeSymbol = cfg.symbol;
    final trx = await getTrxBalance(address);
    final balances = <AssetBalance>[
      AssetBalance(chainKey: chainKey, symbol: nativeSymbol, rawBalance: trx, decimals: cfg.decimals),
    ];
    for (final token in cfg.builtinTokens) {
      final raw = await getTrc20Balance(address, token.contractAddress);
      balances.add(AssetBalance(
        chainKey: chainKey,
        symbol: token.symbol,
        rawBalance: raw,
        decimals: token.decimals,
        contractAddress: token.contractAddress,
      ));
    }
    return balances;
  }

  Future<List<TxRecord>> getTransactionHistory(String address, {int limit = 20}) async {
    try {
      final resp = await _get<Map<String, dynamic>>(
        '/v1/accounts/$address/transactions',
        queryParameters: {'limit': limit, 'only_confirmed': true},
      );
      final data = resp.data ?? {};
      final list = data['data'] as List? ?? [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final raw = m['raw_data'] as Map<String, dynamic>? ?? {};
        final contracts = raw['contract'] as List? ?? [];
        final contract =
            contracts.isNotEmpty ? contracts.first as Map<String, dynamic> : <String, dynamic>{};
        final value = (contract['parameter'] as Map<String, dynamic>?)?['value'] ?? {};
        final amount =
            BigInt.tryParse((value as Map<String, dynamic>)['amount']?.toString() ?? '0') ??
                BigInt.zero;
        final ts = raw['timestamp'] as int? ?? 0;
        return TxRecord(
          hash: m['txID'] as String? ?? '',
          from: value['owner_address'] as String? ?? '',
          to: value['to_address'] as String? ?? '',
          value: amount,
          decimals: chains[chainKey]!.decimals,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
          status: 'confirmed',
          chainKey: chainKey,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TxRecord>> getTrc20TransferHistory(
    String address,
    String contractAddress, {
    int limit = 20,
  }) async {
    try {
      final resp = await _get<Map<String, dynamic>>(
        '/v1/accounts/$address/transactions/trc20',
        queryParameters: {
          'limit': limit,
          'contract_address': contractAddress,
          'only_confirmed': true,
        },
      );
      final data = resp.data ?? {};
      final list = data['data'] as List? ?? [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final valueStr = (m['value'] ?? '0').toString();
        final tokenInfo = m['token_info'] as Map<String, dynamic>? ?? {};
        final decimals = tokenInfo['decimals'] as int? ?? 6;
        final symbol = tokenInfo['symbol'] as String?;
        return TxRecord(
          hash: m['transaction_id'] as String? ?? '',
          from: m['from'] as String? ?? '',
          to: m['to'] as String? ?? '',
          value: BigInt.tryParse(valueStr) ?? BigInt.zero,
          decimals: decimals,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            m['block_timestamp'] as int? ?? 0,
          ),
          status: 'confirmed',
          chainKey: chainKey,
          tokenSymbol: symbol,
          tokenContract: contractAddress,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write operations ──────────────────────────────────────────────────────

  Future<String?> sendTrx({
    required Uint8List privateKey,
    required String to,
    required BigInt amountSun,
  }) async {
    try {
      final from = _toHexAddress(tronAddressToHex(privateKey));
      final buildResp = await _post<Map<String, dynamic>>(
        '/wallet/createtransaction',
        data: {
          'owner_address': from,
          'to_address': _toHexAddress(to),
          'amount': amountSun.toInt(),
        },
      );
      final tx = Map<String, dynamic>.from(buildResp.data ?? {});
      final signed = _signTx(tx, privateKey);
      final broadResp = await _post<Map<String, dynamic>>(
        '/wallet/broadcasttransaction',
        data: signed,
      );
      return (broadResp.data ?? {})['txid'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> sendTrc20({
    required Uint8List privateKey,
    required String contractAddress,
    required String to,
    required BigInt amount,
  }) async {
    try {
      final fromHex = tronAddressToHex(privateKey);
      final toHex = _toHexAddress(to);
      final contractHex = _toHexAddress(contractAddress);
      final parameter = _encodeTrc20TransferParams(toHex, amount);

      final buildResp = await _post<Map<String, dynamic>>(
        '/wallet/triggersmartcontract',
        data: {
          'owner_address': fromHex,
          'contract_address': contractHex,
          'function_selector': 'transfer(address,uint256)',
          'parameter': parameter,
          'fee_limit': 100000000,
          'call_value': 0,
        },
      );
      final body = buildResp.data ?? {};
      final result = body['result'] as Map<String, dynamic>?;
      if (result?['result'] != true) return null;

      final tx = Map<String, dynamic>.from(body['transaction'] as Map<String, dynamic>);
      final signed = _signTx(tx, privateKey);
      final broadResp = await _post<Map<String, dynamic>>(
        '/wallet/broadcasttransaction',
        data: signed,
      );
      return (broadResp.data ?? {})['txid'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Address utilities ─────────────────────────────────────────────────────

  static String tronAddressToHex(Uint8List privateKey) {
    final ethKey = EthPrivateKey(privateKey);
    final pubKeyBytes = ethKey.encodedPublicKey;
    final hash = w3c.keccak256(pubKeyBytes);
    final rawAddr = hash.sublist(12);
    return '41${_bytesToHex(rawAddr)}';
  }

  static String _toHexAddress(String input) {
    if (input.startsWith('41') && input.length == 42) return input;
    final bytes = _base58Decode(input);
    return _bytesToHex(bytes.sublist(0, 21));
  }

  /// ABI-encodes params for transfer(address,uint256).
  /// [toHex] must be 42-char hex starting with '41'. Returns 128-char hex (64 bytes).
  static String _encodeTrc20TransferParams(String toHex, BigInt amount) {
    final addrPadded = toHex.substring(2).padLeft(64, '0');
    var amtHex = amount.toRadixString(16);
    if (amtHex.length.isOdd) amtHex = '0$amtHex';
    return addrPadded + amtHex.padLeft(64, '0');
  }

  Map<String, dynamic> _signTx(Map<String, dynamic> tx, Uint8List privateKey) {
    final txId = tx['txID'] as String;
    final hash = _hexToBytes(txId);
    final ethKey = EthPrivateKey(privateKey);
    final sig = ethKey.signPersonalMessageToUint8List(hash);
    return {...tx, 'signature': [_bytesToHex(sig)]};
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  static const _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static Uint8List _base58Decode(String input) {
    var x = BigInt.zero;
    for (final char in input.split('')) {
      final idx = _base58Alphabet.indexOf(char);
      if (idx < 0) throw FormatException('Invalid base58 char: $char');
      x = x * BigInt.from(58) + BigInt.from(idx);
    }
    var hex = x.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';
    final bytes = _hexToBytes(hex);
    final leadingOnes = input.split('').takeWhile((c) => c == '1').length;
    return Uint8List.fromList([...List.filled(leadingOnes, 0), ...bytes]);
  }
}
