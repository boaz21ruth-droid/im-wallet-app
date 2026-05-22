import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'wallet_models.dart';

class WalletStore {
  static const _kAccounts = 'wv_accounts';
  static const _kSettings = 'wv_settings';
  static const _kNextIndex = 'wv_next_index';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<bool> hasWallet() async {
    final v = await _storage.read(key: 'wv_mnemonic');
    return v != null;
  }

  static Future<List<WalletAccount>> loadAccounts() async {
    final raw = await _storage.read(key: _kAccounts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => WalletAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveAccounts(List<WalletAccount> accounts) async {
    final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _kAccounts, value: raw);
  }

  static Future<WalletSettings> loadSettings() async {
    final raw = await _storage.read(key: _kSettings);
    if (raw == null) return WalletSettings.defaults;
    return WalletSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> saveSettings(WalletSettings settings) async {
    await _storage.write(key: _kSettings, value: jsonEncode(settings.toJson()));
  }

  static Future<int> loadNextIndex() async {
    final raw = await _storage.read(key: _kNextIndex);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  static Future<void> saveNextIndex(int index) async {
    await _storage.write(key: _kNextIndex, value: index.toString());
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
