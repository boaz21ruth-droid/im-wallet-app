// lib/services/wallet/swap/swap_provider.dart
import 'swap_models.dart';

abstract class SwapProvider {
  String get id;
  String get displayName;

  /// True iff this provider can return quotes for `chainKey`.
  bool supportsChain(String chainKey);

  /// Soft quote — used for live "you'll get X" preview as the user types.
  /// Throws `SwapException` on failure.
  Future<SwapPriceResult> getPrice(SwapQuoteRequest req);

  /// Firm quote — returns transaction calldata ready to broadcast.
  /// Throws `SwapException` on failure.
  Future<SwapQuote> getQuote(SwapQuoteRequest req);
}
