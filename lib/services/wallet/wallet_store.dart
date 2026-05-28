import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'wallet_models.dart';

class WalletStore {
  final String _uid;

  WalletStore(String userID) : _uid = userID;

  String get _kMnemonic => 'wv_mnemonic_$_uid';
  String get _kAccounts => 'wv_accounts_$_uid';
  String get _kSettings => 'wv_settings_$_uid';
  String get _kNextIndex => 'wv_next_index_$_uid';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasWallet() async {
    final v = await _storage.read(key: _kMnemonic);
    return v != null;
  }

  Future<List<WalletAccount>> loadAccounts() async {
    final raw = await _storage.read(key: _kAccounts);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => WalletAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAccounts(List<WalletAccount> accounts) async {
    final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _kAccounts, value: raw);
  }

  Future<WalletSettings> loadSettings() async {
    final raw = await _storage.read(key: _kSettings);
    if (raw == null) return WalletSettings.defaults;
    return WalletSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(WalletSettings settings) async {
    await _storage.write(key: _kSettings, value: jsonEncode(settings.toJson()));
  }

  Future<int> loadNextIndex() async {
    final raw = await _storage.read(key: _kNextIndex);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  Future<void> saveNextIndex(int index) async {
    await _storage.write(key: _kNextIndex, value: index.toString());
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccounts);
    await _storage.delete(key: _kSettings);
    await _storage.delete(key: _kNextIndex);
  }
}
