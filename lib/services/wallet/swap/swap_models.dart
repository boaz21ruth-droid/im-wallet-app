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
