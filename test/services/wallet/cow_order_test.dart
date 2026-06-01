// Verifies the CoW order digest integrates with the EIP-712 signer: build a
// digest, sign it, and ecrecover back to the signer. (Exact CoW spec conformance
// is validated by real order submission on Sepolia/mainnet — CoW rejects a wrong
// signature.)
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/crypto.dart' as c;
import 'package:web3dart/web3dart.dart';

import 'package:openim/services/wallet/eip712.dart';
import 'package:openim/services/wallet/swap/cow_order.dart';
import 'package:openim/services/wallet/swap/swap_models.dart';

void main() {
  test('CoW order digest signs and ecrecovers to the signer', () {
    const order = IntentOrder(
      sellToken: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
      buyToken: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      receiver: '0x8E8bEa085A3909A5a09749b195C6bbbd4872b552',
      sellAmount: '100000000',
      buyAmount: '99000000',
      validTo: 1780308625,
      appData:
          '0x0000000000000000000000000000000000000000000000000000000000000000',
      feeAmount: '0',
      kind: 'sell',
      partiallyFillable: false,
      sellTokenBalance: 'erc20',
      buyTokenBalance: 'erc20',
    );

    final digest = CowOrder.digest(
      order,
      chainId: 1,
      verifyingContract: '0x9008D19f58AAbD9eD0D60971565AA8510560ab41',
    );
    expect(digest.length, 32);

    final key = EthPrivateKey.fromHex(
        '0xc85ef7d79691fe79573b1a7064c19c1a9819ebdbd1faaab1a8ec92344438aaf4');
    final sig = Eip712.signDigest(digest, key);
    expect(sig.length, 65);

    final msgSig = c.MsgSignature(
      c.bytesToUnsignedInt(sig.sublist(0, 32)),
      c.bytesToUnsignedInt(sig.sublist(32, 64)),
      sig[64],
    );
    final recovered =
        '0x${c.bytesToHex(c.publicKeyToAddress(c.ecRecover(digest, msgSig)))}';
    expect(recovered.toLowerCase(),
        '0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826');
  });
}
