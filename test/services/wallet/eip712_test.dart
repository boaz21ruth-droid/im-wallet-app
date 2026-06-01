// Verifies the EIP-712 signer against the canonical "Mail" vector from the
// EIP-712 spec (known domain separator, digest, and signature) plus an
// ecrecover round-trip. This deterministically proves the keystone offline.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/crypto.dart' as c;
import 'package:web3dart/web3dart.dart';

import 'package:openim/services/wallet/eip712.dart';

void main() {
  // EIP-712 spec example.
  const verifyingContract = '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC';
  const fromWallet = '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826';
  const toWallet = '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB';
  const privKey =
      '0xc85ef7d79691fe79573b1a7064c19c1a9819ebdbd1faaab1a8ec92344438aaf4';

  Uint8List personHash(String name, String wallet) => Eip712.hashStruct([
        Eip712.typeHash('Person(string name,address wallet)'),
        Eip712.hashString(name),
        Eip712.addressWord(wallet),
      ]);

  test('domain separator matches the known vector', () {
    final ds = Eip712.domainSeparator(
      name: 'Ether Mail',
      version: '1',
      chainId: 1,
      verifyingContract: verifyingContract,
    );
    expect(c.bytesToHex(ds),
        'f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f');
  });

  test('full Mail digest matches the known vector', () {
    final ds = Eip712.domainSeparator(
      name: 'Ether Mail',
      version: '1',
      chainId: 1,
      verifyingContract: verifyingContract,
    );
    final mailStruct = Eip712.hashStruct([
      Eip712.typeHash(
          'Mail(Person from,Person to,string contents)Person(string name,address wallet)'),
      personHash('Cow', fromWallet),
      personHash('Bob', toWallet),
      Eip712.hashString('Hello, Bob!'),
    ]);
    final digest = Eip712.digest(ds, mailStruct);
    expect(c.bytesToHex(digest),
        'be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2');
  });

  test('signature matches the known vector and ecrecovers to the signer', () {
    final ds = Eip712.domainSeparator(
      name: 'Ether Mail',
      version: '1',
      chainId: 1,
      verifyingContract: verifyingContract,
    );
    final mailStruct = Eip712.hashStruct([
      Eip712.typeHash(
          'Mail(Person from,Person to,string contents)Person(string name,address wallet)'),
      personHash('Cow', fromWallet),
      personHash('Bob', toWallet),
      Eip712.hashString('Hello, Bob!'),
    ]);
    final digest = Eip712.digest(ds, mailStruct);

    final key = EthPrivateKey.fromHex(privKey);
    final sig = Eip712.signDigest(digest, key);

    expect(sig.length, 65);
    final r = c.bytesToHex(sig.sublist(0, 32));
    final s = c.bytesToHex(sig.sublist(32, 64));
    final v = sig[64];
    expect(r,
        '4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d');
    expect(s,
        '07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b91562');
    expect(v, 28);

    // ecrecover the 65-byte signature back to the signer address.
    final msgSig = c.MsgSignature(
      c.bytesToUnsignedInt(sig.sublist(0, 32)),
      c.bytesToUnsignedInt(sig.sublist(32, 64)),
      sig[64],
    );
    final recovered = c.publicKeyToAddress(c.ecRecover(digest, msgSig));
    expect('0x${c.bytesToHex(recovered)}'.toLowerCase(), fromWallet.toLowerCase());
  });
}
