// lib/services/wallet/eip712.dart
//
// Minimal EIP-712 typed-data signer built on web3dart's raw secp256k1.sign,
// which signs a precomputed 32-byte digest WITHOUT adding its own keccak/EIP-191
// prefix. No external dependency. Used for intent-based swaps (CoW orders, and
// later UniswapX/Permit2/Fusion).
//
// Every atomic EIP-712 field (address, uintN, bytes32, bool) encodes to a single
// 32-byte ABI word; dynamic `string`/`bytes` fields encode as keccak256(value).
import 'dart:typed_data';

import 'package:web3dart/crypto.dart' as c;
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

class Eip712 {
  /// keccak256 of a type string, e.g. the domain/struct type hash.
  static Uint8List typeHash(String type) => c.keccakUtf8(type);

  /// keccak256(value) for a dynamic string/bytes field.
  static Uint8List hashString(String s) => c.keccakUtf8(s);

  // ── 32-byte ABI word encoders ──────────────────────────────────────────────
  static Uint8List _rightAligned(Uint8List bytes) {
    final w = Uint8List(32);
    w.setRange(32 - bytes.length, 32, bytes);
    return w;
  }

  static Uint8List addressWord(String hex) =>
      _rightAligned(c.hexToBytes(hex)); // 20 bytes → left-padded to 32

  static Uint8List uintWord(BigInt v) => _rightAligned(c.unsignedIntToBytes(v));

  static Uint8List boolWord(bool v) => uintWord(v ? BigInt.one : BigInt.zero);

  /// A field that is itself already 32 bytes (bytes32, or a precomputed hash).
  static Uint8List bytes32Word(Uint8List b) {
    if (b.length == 32) return b;
    final w = Uint8List(32);
    w.setRange(0, b.length, b); // bytes32 is left-aligned
    return w;
  }

  static Uint8List bytes32Hex(String hex) => bytes32Word(c.hexToBytes(hex));

  static Uint8List _concat(List<Uint8List> parts) {
    final b = BytesBuilder();
    for (final p in parts) {
      b.add(p);
    }
    return b.toBytes();
  }

  /// keccak256(abiEncode(words...)) — `words` are pre-encoded 32-byte ABI words
  /// (the first is normally the struct/type hash).
  static Uint8List hashStruct(List<Uint8List> words) =>
      c.keccak256(_concat(words));

  /// EIP-712 domain separator for a standard
  /// `EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)`.
  static Uint8List domainSeparator({
    required String name,
    required String version,
    required int chainId,
    required String verifyingContract,
  }) {
    return hashStruct([
      typeHash(
          'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
      hashString(name),
      hashString(version),
      uintWord(BigInt.from(chainId)),
      addressWord(verifyingContract),
    ]);
  }

  /// The signing digest: keccak256(0x19 0x01 ‖ domainSeparator ‖ structHash).
  static Uint8List digest(Uint8List domainSeparator, Uint8List structHash) {
    return c.keccak256(_concat([
      Uint8List.fromList([0x19, 0x01]),
      domainSeparator,
      structHash,
    ]));
  }

  /// Signs a 32-byte EIP-712 digest, returning a 65-byte `r ‖ s ‖ v` signature
  /// (v = 27/28) as required by EIP-712 signature schemes.
  static Uint8List signDigest(Uint8List digest32, EthPrivateKey key) {
    final sig = c.sign(digest32, key.privateKey);
    final out = Uint8List(65);
    final r = c.unsignedIntToBytes(sig.r);
    final s = c.unsignedIntToBytes(sig.s);
    out.setRange(32 - r.length, 32, r);
    out.setRange(64 - s.length, 64, s);
    out[64] = sig.v;
    return out;
  }

  /// Hex form (0x-prefixed) of [signDigest], for JSON submission.
  static String signDigestHex(Uint8List digest32, EthPrivateKey key) =>
      '0x${c.bytesToHex(signDigest(digest32, key))}';
}
