import 'dart:convert';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart' as w3crypto;

class WalletKey {
  static String generateMnemonic() => bip39.generateMnemonic();

  static bool validateMnemonic(String mnemonic) => bip39.validateMnemonic(mnemonic);

  // Returns seed bytes — caller is responsible for scrubbing
  static Uint8List mnemonicToSeed(Uint8List mnemonicBytes) {
    final mnemonic = utf8.decode(mnemonicBytes);
    return bip39.mnemonicToSeed(mnemonic);
  }

  // EVM: m/44'/60'/0'/0/{index}
  static EthPrivateKey deriveEVMKey(Uint8List seed, int index) {
    final node = bip32.BIP32.fromSeed(seed)
        .derivePath("m/44'/60'/0'/0/$index");
    return EthPrivateKey(node.privateKey!);
  }

  static String deriveEVMAddress(Uint8List seed, int index) {
    final key = deriveEVMKey(seed, index);
    return key.address.hexEip55;
  }

  // TRON: m/44'/195'/0'/0/{index}
  static Uint8List deriveTRONPrivKey(Uint8List seed, int index) {
    final node = bip32.BIP32.fromSeed(seed)
        .derivePath("m/44'/195'/0'/0/$index");
    return Uint8List.fromList(node.privateKey!);
  }

  static String deriveTRONAddress(Uint8List seed, int index) {
    final privKey = deriveTRONPrivKey(seed, index);
    try {
      final addr = _tronAddressFromPrivKey(privKey);
      return addr;
    } finally {
      privKey.fillRange(0, privKey.length, 0);
    }
  }

  static String _tronAddressFromPrivKey(Uint8List privKey) {
    // 1. Derive uncompressed public key (65 bytes, starts with 0x04)
    final pubKey = _privKeyToUncompressedPub(privKey);
    // 2. Remove 0x04 prefix → 64 bytes
    final pubKeyBody = pubKey.sublist(1);
    // 3. Keccak256 → 32 bytes
    final hash = w3crypto.keccak256(pubKeyBody);
    // 4. Take last 20 bytes
    final rawAddr = hash.sublist(12);
    // 5. Prepend 0x41
    final tronRaw = Uint8List(21);
    tronRaw[0] = 0x41;
    tronRaw.setRange(1, 21, rawAddr);
    // 6. Double SHA256 checksum (first 4 bytes)
    final check1 = sha256.convert(tronRaw).bytes;
    final check2 = sha256.convert(check1).bytes;
    // 7. Append checksum
    final full = Uint8List(25);
    full.setRange(0, 21, tronRaw);
    full.setRange(21, 25, check2.sublist(0, 4));
    // 8. Base58 encode
    return _base58Encode(full);
  }

  static Uint8List _privKeyToUncompressedPub(Uint8List privKey) {
    // Use web3dart's secp256k1 — it computes the public key from a private key
    final ethKey = EthPrivateKey(privKey);
    // EthPrivateKey.publicKey gives us the compressed or uncompressed key
    // We need uncompressed (65 bytes with 0x04 prefix)
    // web3dart stores public key as 64 bytes (without prefix) internally
    final pubKeyBytes = ethKey.encodedPublicKey;
    // Ensure we return uncompressed format (64 bytes raw → prepend 0x04)
    if (pubKeyBytes.length == 64) {
      final full = Uint8List(65);
      full[0] = 0x04;
      full.setRange(1, 65, pubKeyBytes);
      return full;
    }
    return Uint8List.fromList(pubKeyBytes);
  }

  static const _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String _base58Encode(Uint8List input) {
    var x = BigInt.zero;
    for (final byte in input) {
      x = x * BigInt.from(256) + BigInt.from(byte);
    }
    var result = '';
    while (x > BigInt.zero) {
      final mod = (x % BigInt.from(58)).toInt();
      result = _base58Alphabet[mod] + result;
      x = x ~/ BigInt.from(58);
    }
    for (final byte in input) {
      if (byte == 0) {
        result = '1$result';
      } else {
        break;
      }
    }
    return result;
  }
}
