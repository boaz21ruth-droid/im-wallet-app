import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/export.dart';
import 'vault_crypto.dart';

class MnemonicVault {
  static const _kMnemonic = 'wv_mnemonic';
  static const _kBiometricKey = 'wv_biometric_key';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final _localAuth = LocalAuthentication();

  Uint8List? _mnemonicBytes;

  bool get isUnlocked => _mnemonicBytes != null;

  Future<void> create(Uint8List mnemonicBytes, String password) async {
    final encrypted = await VaultCrypto.encrypt(mnemonicBytes, password);
    await _storage.write(key: _kMnemonic, value: encrypted);
  }

  Future<bool> unlock(String password) async {
    try {
      final encrypted = await _storage.read(key: _kMnemonic);
      if (encrypted == null) return false;
      final bytes = await VaultCrypto.decrypt(encrypted, password);
      _scrub(_mnemonicBytes);
      _mnemonicBytes = bytes;
      return true;
    } catch (_) {
      return false; // GCM tag fail = wrong password
    }
  }

  Future<bool> unlockWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access wallet',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated) return false;

      final keyB64 = await _storage.read(
        key: _kBiometricKey,
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.passcode,
        ),
      );
      if (keyB64 == null) return false;

      final aesKey = base64.decode(keyB64);
      final encrypted = await _storage.read(key: _kMnemonic);
      if (encrypted == null) return false;

      final bytes = await _decryptWithRawKey(encrypted, aesKey);
      _scrub(_mnemonicBytes);
      _mnemonicBytes = bytes;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Called once when user enables biometric — stores password-derived AES key
  Future<void> enableBiometric(String password) async {
    final encrypted = await _storage.read(key: _kMnemonic);
    if (encrypted == null) throw StateError('No wallet');
    final key = await _extractAesKey(encrypted, password);
    await _storage.write(
      key: _kBiometricKey,
      value: base64.encode(key),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.passcode,
      ),
      aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: _kBiometricKey);
  }

  Future<bool> isBiometricAvailable() async {
    return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
  }

  // Minimises plaintext exposure — use for key derivation and export operations
  Future<T> withMnemonic<T>(String password, Future<T> Function(Uint8List m) fn) async {
    final encrypted = await _storage.read(key: _kMnemonic);
    if (encrypted == null) throw StateError('No wallet');
    final bytes = await VaultCrypto.decrypt(encrypted, password);
    try {
      return await fn(bytes);
    } finally {
      _scrub(bytes);
    }
  }

  Future<T> withCachedMnemonic<T>(Future<T> Function(Uint8List m) fn) async {
    if (_mnemonicBytes == null) throw StateError('Wallet locked');
    return fn(_mnemonicBytes!);
  }

  void lock() {
    _scrub(_mnemonicBytes);
    _mnemonicBytes = null;
  }

  Future<void> changePassword(String oldPwd, String newPwd) async {
    final copy = await withMnemonic(oldPwd, (m) async => Uint8List.fromList(m));
    try {
      await create(copy, newPwd);
    } finally {
      _scrub(copy);
    }
  }

  Future<void> deleteWallet() async {
    lock();
    await _storage.delete(key: _kMnemonic);
    await _storage.delete(key: _kBiometricKey);
  }

  static void _scrub(Uint8List? bytes) {
    if (bytes != null) bytes.fillRange(0, bytes.length, 0);
  }

  // Re-derive the AES key from the stored salt — for biometric escrow
  static Future<Uint8List> _extractAesKey(String encoded, String password) async {
    final bytes = base64.decode(encoded);
    final salt = bytes.sublist(0, 32);
    return VaultCrypto.deriveKey(password, Uint8List.fromList(salt));
  }

  // Decrypt with raw AES key (biometric path — skips PBKDF2)
  static Future<Uint8List> _decryptWithRawKey(String encoded, Uint8List key) async {
    final bytes = base64.decode(encoded);
    final nonce = bytes.sublist(32, 44);
    final cipherAndTag = bytes.sublist(44);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          128,
          Uint8List.fromList(nonce),
          Uint8List(0),
        ),
      );
    return gcm.process(Uint8List.fromList(cipherAndTag));
  }
}
