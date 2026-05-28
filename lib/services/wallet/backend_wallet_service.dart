import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';
import 'wallet_models.dart';

class BackendWalletService {
  static String get _baseUrl => Config.appAuthUrl;

  static Map<String, String> _headers() {
    final token = DataSp.chatToken ?? '';
    return {
      'Content-Type': 'application/json',
      'token': token,
    };
  }

  /// Registers all wallet addresses with im-business on first unlock.
  static Future<void> registerAddresses(Map<String, String> addresses) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/wallet/addresses'),
        headers: _headers(),
        body: jsonEncode({'addresses': addresses}),
      );
      if (resp.statusCode != 200) {
        throw Exception('registerAddresses: ${resp.statusCode}');
      }
    } catch (_) {
      // Best-effort — wallet still works without backend registration
    }
  }

  /// Returns wallet addresses previously registered by this IM account.
  /// Returns null when the backend is unreachable so callers can keep local wallet flows available.
  static Future<Map<String, String>?> getRegisteredAddresses() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/wallet/addresses'), headers: _headers())
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode != 200) return null;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if ((json['errCode'] as int? ?? 1) != 0) return null;

      final data = json['data'] as Map<String, dynamic>?;
      final raw = data?['addresses'] as Map<String, dynamic>?;
      if (raw == null) return {};

      return raw.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return null;
    }
  }

  /// Fetches transaction history from the backend.
  /// Returns null if the backend is unreachable (caller falls back to client-side).
  static Future<List<TxRecord>?> getTxHistory({
    required String chainKey,
    String? contractAddress,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var url =
          '$_baseUrl/wallet/tx-history?chain=$chainKey&page=$page&limit=$limit';
      if (contractAddress != null && contractAddress.isNotEmpty) {
        url += '&contract=$contractAddress';
      }

      final resp = await http
          .get(Uri.parse(url), headers: _headers())
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return null;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if ((json['errCode'] as int? ?? 1) != 0) return null;

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return [];

      final records = (data['records'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_parseTxRecord)
          .toList();

      return records;
    } catch (_) {
      return null; // caller falls back to client-side
    }
  }

  static TxRecord _parseTxRecord(Map<String, dynamic> m) {
    final ts = m['blockTimestamp'] as String? ?? '';
    final dt = ts.isNotEmpty
        ? DateTime.tryParse(ts) ?? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final rawValue = m['value'] as String? ?? '0';
    final decimals = (m['decimals'] as int?) ?? 18;
    final bigValue = BigInt.tryParse(rawValue) ?? BigInt.zero;

    return TxRecord(
      hash: m['hash'] as String? ?? '',
      from: m['from'] as String? ?? '',
      to: m['to'] as String? ?? '',
      value: bigValue,
      decimals: decimals,
      timestamp: dt,
      status: 'confirmed',
      chainKey: m['chainKey'] as String? ?? '',
      tokenSymbol: m['tokenSymbol'] as String?,
      tokenContract: m['tokenContract'] as String?,
    );
  }
}
