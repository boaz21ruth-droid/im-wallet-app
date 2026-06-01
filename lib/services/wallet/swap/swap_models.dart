// lib/services/wallet/swap/swap_models.dart

class SwapToken {
  final String chainKey;
  final String symbol;
  final int decimals;
  /// null = native token (ETH/BNB/POL/MATIC).
  final String? contractAddress;

  const SwapToken({
    required this.chainKey,
    required this.symbol,
    required this.decimals,
    this.contractAddress,
  });

  bool get isNative => contractAddress == null;

  @override
  bool operator ==(Object other) =>
      other is SwapToken &&
      other.chainKey == chainKey &&
      other.symbol == symbol &&
      other.contractAddress == contractAddress;

  @override
  int get hashCode => Object.hash(chainKey, symbol, contractAddress);
}

class SwapQuoteRequest {
  final String chainKey;
  final SwapToken sellToken;
  final SwapToken buyToken;
  final BigInt sellAmount;
  final String takerAddress;
  final int slippageBps; // 50 = 0.5%

  const SwapQuoteRequest({
    required this.chainKey,
    required this.sellToken,
    required this.buyToken,
    required this.sellAmount,
    required this.takerAddress,
    required this.slippageBps,
  });
}

class SwapFees {
  final BigInt? integratorFeeAmount;
  final String? integratorFeeToken;
  final BigInt? zeroExFeeAmount;
  final BigInt? gasFeeAmount;

  const SwapFees({
    this.integratorFeeAmount,
    this.integratorFeeToken,
    this.zeroExFeeAmount,
    this.gasFeeAmount,
  });
}

class ApprovalIssue {
  final String tokenAddress;
  final String spender;
  final BigInt requiredAmount;

  const ApprovalIssue({
    required this.tokenAddress,
    required this.spender,
    required this.requiredAmount,
  });
}

class SwapPriceResult {
  final BigInt buyAmount;
  final BigInt? gasEstimate;
  final SwapFees fees;
  final String providerId;

  const SwapPriceResult({
    required this.buyAmount,
    this.gasEstimate,
    required this.fees,
    required this.providerId,
  });
}

class SwapQuote {
  final BigInt buyAmount;
  final BigInt minBuyAmount;
  final String to;
  final String data;
  final BigInt value;
  final BigInt? gas;
  final BigInt? gasPrice;
  final ApprovalIssue? approval;
  final SwapFees fees;
  final String providerId;
  final DateTime? expiresAt;

  const SwapQuote({
    required this.buyAmount,
    required this.minBuyAmount,
    required this.to,
    required this.data,
    required this.value,
    this.gas,
    this.gasPrice,
    this.approval,
    required this.fees,
    required this.providerId,
    this.expiresAt,
  });
}

/// Cross-chain (bridge) quote from LI.FI via /wallet/bridge/quote. Carries a
/// source-chain signable tx plus delivery metadata. The client signs+broadcasts
/// `to`/`data`/`value` on the source chain, then polls bridge status.
class BridgeQuote {
  final String tool; // chosen bridge, e.g. "across"
  final String fromChain;
  final String toChain;
  final BigInt toAmount; // expected received on dest chain
  final BigInt toAmountMin;
  final String to;
  final String data;
  final BigInt value;
  final BigInt? gas;
  final BigInt? gasPrice;
  final ApprovalIssue? approval; // source-chain ERC20 approval (null for native)
  final int executionDurationSec;

  const BridgeQuote({
    required this.tool,
    required this.fromChain,
    required this.toChain,
    required this.toAmount,
    required this.toAmountMin,
    required this.to,
    required this.data,
    required this.value,
    this.gas,
    this.gasPrice,
    this.approval,
    required this.executionDurationSec,
  });
}

/// Cross-chain delivery state from /wallet/bridge/status.
enum BridgeStatusKind { pending, done, failed, notFound, unknown }

class BridgeStatus {
  final BridgeStatusKind kind;
  final String? destTxHash;
  final String? explorer;

  const BridgeStatus({required this.kind, this.destTxHash, this.explorer});

  static BridgeStatusKind kindFrom(String? s) {
    switch (s) {
      case 'DONE':
        return BridgeStatusKind.done;
      case 'FAILED':
      case 'INVALID':
        return BridgeStatusKind.failed;
      case 'PENDING':
        return BridgeStatusKind.pending;
      case 'NOT_FOUND':
        return BridgeStatusKind.notFound;
      default:
        return BridgeStatusKind.unknown;
    }
  }
}

/// Reason for a quote/price failure. UI consumes this to pick the right
/// disabled-button text without parsing error strings.
enum SwapErrorKind {
  noApiKey,
  chainNotSupported,
  noLiquidity,
  rateLimited,
  network,
  invalidParams,
  unknown,
}

class SwapException implements Exception {
  final SwapErrorKind kind;
  final String message;
  const SwapException(this.kind, this.message);

  @override
  String toString() => 'SwapException($kind): $message';
}
