import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

class VaultCrypto {
  static const _saltLen = 32;
  static const _nonceLen = 12;
  static const _tagBits = 128;

  static Uint8List _randomBytes(int len) {
    final rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(len, (_) => rng.nextInt(256)));
  }

  // Top-level-compatible static method for compute() Isolate
  static Uint8List _pbkdf2Worker(Map<String, dynamic> params) {
    final password = Uint8List.fromList(utf8.encode(params['password'] as String));
    final salt = params['salt'] as Uint8List;
    final iters = params['iterations'] as int;
    final deriv = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    deriv.init(Pbkdf2Parameters(salt, iters, 32));
    return deriv.process(password);
  }

  static Future<Uint8List> deriveKey(
    String password,
    Uint8List salt, {
    int iterations = 310000,
  }) =>
      compute(
        _pbkdf2Worker,
        {'password': password, 'salt': salt, 'iterations': iterations},
      );

  static Future<String> encrypt(Uint8List plaintext, String password) async {
    final salt = _randomBytes(_saltLen);
    final nonce = _randomBytes(_nonceLen); // Fresh nonce every call — GCM critical
    final key = await deriveKey(password, salt);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), _tagBits, nonce, Uint8List(0)));
    final cipherAndTag = gcm.process(plaintext);
    // Format: salt(32) || nonce(12) || ciphertext+tag
    final out = Uint8List(_saltLen + _nonceLen + cipherAndTag.length);
    out.setRange(0, _saltLen, salt);
    out.setRange(_saltLen, _saltLen + _nonceLen, nonce);
    out.setRange(_saltLen + _nonceLen, out.length, cipherAndTag);
    return base64.encode(out);
  }

  static Future<Uint8List> decrypt(String encoded, String password) async {
    final bytes = base64.decode(encoded);
    final salt = bytes.sublist(0, _saltLen);
    final nonce = bytes.sublist(_saltLen, _saltLen + _nonceLen);
    final cipherAndTag = bytes.sublist(_saltLen + _nonceLen);
    final key = await deriveKey(password, Uint8List.fromList(salt));
    final gcm = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          _tagBits,
          Uint8List.fromList(nonce),
          Uint8List(0),
        ),
      );
    // Throws InvalidCipherTextException if GCM tag fails → wrong password
    return gcm.process(Uint8List.fromList(cipherAndTag));
  }

  // Fast password verification (lower iterations, just to check correctness)
  static Future<bool> verifyPassword(String encoded, String password) async {
    try {
      await decrypt(encoded, password);
      return true;
    } catch (_) {
      return false;
    }
  }
}
