import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';

/// Result of POST /user/totp/setup.
class TotpSetupResult {
  final String secret;      // base32 secret (shown so users can manually enter)
  final String otpauthUrl;  // otpauth://... — rendered as a QR code

  TotpSetupResult({required this.secret, required this.otpauthUrl});
}

/// Reasons a TOTP API call can fail. Maps to backend error codes 1600–1603.
enum TotpError {
  invalid,        // 1600 — wrong code
  locked,         // 1601 — too many wrong attempts
  alreadyEnabled, // 1602 — setup called while already enabled
  notEnabled,     // 1603 — disable/verify called when not enabled
  setupExpired,   // 1604 — pending setup secret expired (10 min Redis TTL)
  unauthorized,   // 1501 — token expired (handled globally; surfaced here too)
  network,        // unreachable / non-JSON / timeout
}

class TotpException implements Exception {
  final TotpError kind;
  final String message;
  TotpException(this.kind, this.message);

  @override
  String toString() => 'TotpException(${kind.name}: $message)';
}

/// Client for the /user/totp/* and /wallet/totp/verify endpoints.
///
/// All methods throw [TotpException] on failure. Success paths return either
/// the decoded data ([setup]) or void ([enable], [disable]).
class TotpService {
  static String get _base => Config.appAuthUrl;

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'token': DataSp.chatToken ?? '',
      };

  static Future<TotpSetupResult> setup() async {
    final json = await _post('/user/totp/setup', {});
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return TotpSetupResult(
      secret: data['secret'] as String? ?? '',
      otpauthUrl: data['otpauthUrl'] as String? ?? '',
    );
  }

  static Future<void> enable(String code) async {
    await _post('/user/totp/enable', {'code': code});
  }

  static Future<void> disable(String code) async {
    await _post('/user/totp/disable', {'code': code});
  }

  /// Fetches current enabled status. Returns false on network errors so callers
  /// don't block UI for a non-critical check.
  static Future<bool> status() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/user/totp/status'), headers: _headers())
          .timeout(const Duration(seconds: 8));
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if ((json['errCode'] as int? ?? 1) != 0) return false;
      final data = json['data'] as Map<String, dynamic>? ?? const {};
      return data['enabled'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Pre-transfer gating check. Returns true if the code is accepted (or the
  /// user has no TOTP configured server-side). Throws on invalid/locked/network.
  static Future<bool> verifyForTransfer(String code) async {
    final json = await _post('/wallet/totp/verify', {'code': code});
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return data['valid'] as bool? ?? false;
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    http.Response resp;
    try {
      resp = await http
          .post(
            Uri.parse('$_base$path'),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw TotpException(TotpError.network, e.toString());
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw TotpException(TotpError.network, 'invalid response (${resp.statusCode})');
    }

    final errCode = json['errCode'] as int? ?? -1;
    if (errCode == 0) return json;

    final msg = json['errMsg'] as String? ?? 'unknown error';
    switch (errCode) {
      case 1501:
        throw TotpException(TotpError.unauthorized, msg);
      case 1600:
        throw TotpException(TotpError.invalid, msg);
      case 1601:
        throw TotpException(TotpError.locked, msg);
      case 1602:
        throw TotpException(TotpError.alreadyEnabled, msg);
      case 1603:
        throw TotpException(TotpError.notEnabled, msg);
      case 1604:
        throw TotpException(TotpError.setupExpired, msg);
      default:
        throw TotpException(TotpError.network, msg);
    }
  }
}
