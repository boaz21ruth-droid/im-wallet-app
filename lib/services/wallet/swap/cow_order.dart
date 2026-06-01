// lib/services/wallet/swap/cow_order.dart
//
// Builds the EIP-712 signing digest for a CoW GPv2 order using the generic
// Eip712 signer. Domain: name="Gnosis Protocol", version="v2".
import 'dart:typed_data';

import '../eip712.dart';
import 'swap_models.dart';

class CowOrder {
  static const _orderType =
      'Order(address sellToken,address buyToken,address receiver,uint256 sellAmount,'
      'uint256 buyAmount,uint32 validTo,bytes32 appData,uint256 feeAmount,string kind,'
      'bool partiallyFillable,string sellTokenBalance,string buyTokenBalance)';

  /// The 32-byte EIP-712 digest the user signs for [order] on [chainId] with the
  /// given GPv2Settlement [verifyingContract].
  static Uint8List digest(
    IntentOrder order, {
    required int chainId,
    required String verifyingContract,
  }) {
    final structHash = Eip712.hashStruct([
      Eip712.typeHash(_orderType),
      Eip712.addressWord(order.sellToken),
      Eip712.addressWord(order.buyToken),
      Eip712.addressWord(order.receiver),
      Eip712.uintWord(BigInt.parse(order.sellAmount)),
      Eip712.uintWord(BigInt.parse(order.buyAmount)),
      Eip712.uintWord(BigInt.from(order.validTo)),
      Eip712.bytes32Hex(order.appData),
      Eip712.uintWord(BigInt.parse(order.feeAmount)),
      Eip712.hashString(order.kind),
      Eip712.boolWord(order.partiallyFillable),
      Eip712.hashString(order.sellTokenBalance),
      Eip712.hashString(order.buyTokenBalance),
    ]);
    final domain = Eip712.domainSeparator(
      name: 'Gnosis Protocol',
      version: 'v2',
      chainId: chainId,
      verifyingContract: verifyingContract,
    );
    return Eip712.digest(domain, structHash);
  }
}
