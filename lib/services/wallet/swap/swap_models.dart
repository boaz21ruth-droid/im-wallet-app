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

/// A CoW GPv2 order the user signs (EIP-712). Field names/types mirror the Go
/// intent.Order and the EIP-712 Order struct.
class IntentOrder {
  final String sellToken;
  final String buyToken;
  final String receiver;
  final String sellAmount;
  final String buyAmount;
  final int validTo;
  final String appData; // 32-byte hash
  final String feeAmount;
  final String kind;
  final bool partiallyFillable;
  final String sellTokenBalance;
  final String buyTokenBalance;

  const IntentOrder({
    required this.sellToken,
    required this.buyToken,
    required this.receiver,
    required this.sellAmount,
    required this.buyAmount,
    required this.validTo,
    required this.appData,
    required this.feeAmount,
    required this.kind,
    required this.partiallyFillable,
    required this.sellTokenBalance,
    required this.buyTokenBalance,
  });

  factory IntentOrder.fromJson(Map<String, dynamic> j) => IntentOrder(
        sellToken: j['sellToken'] as String,
        buyToken: j['buyToken'] as String,
        receiver: j['receiver'] as String,
        sellAmount: j['sellAmount'] as String,
        buyAmount: j['buyAmount'] as String,
        validTo: j['validTo'] as int,
        appData: j['appData'] as String,
        feeAmount: j['feeAmount'] as String,
        kind: j['kind'] as String,
        partiallyFillable: j['partiallyFillable'] as bool,
        sellTokenBalance: j['sellTokenBalance'] as String,
        buyTokenBalance: j['buyTokenBalance'] as String,
      );

  Map<String, dynamic> toJson() => {
        'sellToken': sellToken,
        'buyToken': buyToken,
        'receiver': receiver,
        'sellAmount': sellAmount,
        'buyAmount': buyAmount,
        'validTo': validTo,
        'appData': appData,
        'feeAmount': feeAmount,
        'kind': kind,
        'partiallyFillable': partiallyFillable,
        'sellTokenBalance': sellTokenBalance,
        'buyTokenBalance': buyTokenBalance,
      };
}

/// Intent (CoW) quote from /wallet/intent/quote: the order to sign + the EIP-712
/// domain inputs + the pre-trade approval spender.
class IntentQuote {
  final IntentOrder order;
  final int chainId;
  final String verifyingContract; // GPv2Settlement
  final String approvalSpender; // GPv2VaultRelayer
  final int quoteId;
  final BigInt expectedBuyAmount; // pre-slippage estimate, for display

  const IntentQuote({
    required this.order,
    required this.chainId,
    required this.verifyingContract,
    required this.approvalSpender,
    required this.quoteId,
    required this.expectedBuyAmount,
  });
}

/// Intent order settlement state from /wallet/intent/status.
enum IntentStatusKind { open, fulfilled, cancelled, expired, unknown }

class IntentStatus {
  final IntentStatusKind kind;
  const IntentStatus(this.kind);

  static IntentStatusKind kindFrom(String? s) {
    switch (s) {
      case 'fulfilled':
        return IntentStatusKind.fulfilled;
      case 'cancelled':
        return IntentStatusKind.cancelled;
      case 'expired':
        return IntentStatusKind.expired;
      case 'open':
      case 'presignaturePending':
        return IntentStatusKind.open;
      default:
        return IntentStatusKind.unknown;
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
