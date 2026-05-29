import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';

import 'remote_swap_config.dart';

/// Caches the runtime swap config served by GET /wallet/swap_config.
///
/// `current` always returns a non-null value: cached, persisted, or
/// compile-time defaults. Consumers (`ZeroExProvider`, `SwapLogic`,
/// `EvmService` callers) should read through `current` rather than referencing
/// the constants in `swap_config.dart` directly.
class SwapConfigService extends GetxService {
  static SwapConfigService get to => Get.find<SwapConfigService>();

  static const _storageKey = 'wallet_swap_config_v1';

  RemoteSwapConfig _current = RemoteSwapConfig.fromDefaults();

  RemoteSwapConfig get current => _current;

  /// Hydrates from persisted storage if any. Safe to call multiple times.
  Future<void> loadFromStorage() async {
    try {
      final raw = SpUtil().getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _current = RemoteSwapConfig.fromJson(json).withDefaultsFallback();
    } catch (e) {
      debugPrint('SwapConfigService.loadFromStorage failed: $e');
    }
  }

  /// Fetches the latest config from im-business and replaces the in-memory +
  /// persisted copy. On any failure (offline, 401, timeout, parse) the
  /// existing `current` is kept and `null` is returned so the caller can log.
  Future<RemoteSwapConfig?> fetchAndCache() async {
    final token = DataSp.chatToken ?? '';
    if (token.isEmpty) {
      debugPrint('SwapConfigService.fetchAndCache: no chatToken, skipping');
      return null;
    }
    try {
      final resp = await http.get(
        Uri.parse('${Config.appAuthUrl}/wallet/swap_config'),
        headers: {
          'Content-Type': 'application/json',
          'token': token,
        },
      ).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        debugPrint(
            'SwapConfigService.fetchAndCache: HTTP ${resp.statusCode}');
        return null;
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if ((body['errCode'] as int? ?? 1) != 0) {
        debugPrint(
            'SwapConfigService.fetchAndCache: errCode=${body['errCode']}');
        return null;
      }
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;

      final parsed =
          RemoteSwapConfig.fromJson(data).withDefaultsFallback();
      _current = parsed;
      await SpUtil().putString(_storageKey, jsonEncode(parsed.toJson()));
      return parsed;
    } catch (e) {
      debugPrint('SwapConfigService.fetchAndCache exception: $e');
      return null;
    }
  }
}
