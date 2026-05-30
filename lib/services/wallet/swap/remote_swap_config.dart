// DTOs for GET /wallet/swap_config. Mirror the Go SwapConfig struct in
// internal/config/swap.go; field names must stay in sync.
//
// Compile-time defaults in swap_config.dart are mapped into these same DTOs
// when the backend is unreachable, so call sites read a single source of truth.

import 'swap_config.dart';
import '../chain_config.dart' as cc;

class RemoteSwapConfig {
  // Aggregator credentials are NOT part of this DTO: quote aggregation and API
  // keys live server-side in im-business. The client only needs per-chain RPCs,
  // fee recipient, router allow-list, and limits.
  final Map<String, RemoteChainConfig> chains;
  final RemoteLimits limits;

  const RemoteSwapConfig({
    required this.chains,
    required this.limits,
  });

  /// Builds a config from the compile-time defaults baked into the APK.
  /// Used when the backend is unreachable or hasn't yet been hit on a fresh
  /// install (and as the seed value before any fetch completes).
  factory RemoteSwapConfig.fromDefaults() {
    final defaultChains = <String, RemoteChainConfig>{};
    for (final key in kZeroxSupportedChains) {
      final cfg = cc.chains[key];
      defaultChains[key] = RemoteChainConfig(
        rpcs: cfg?.rpcs ?? const [],
        feeRecipient: kFeeRecipients[key] ?? '',
        allowedRouters: const [kZeroxAllowanceHolder],
      );
    }
    return RemoteSwapConfig(
      chains: defaultChains,
      limits: const RemoteLimits(
        largeAmountUsdThreshold: 10000,
        priceDriftBps: 100,
        approveReceiptTimeoutSeconds: 60,
      ),
    );
  }

  factory RemoteSwapConfig.fromJson(Map<String, dynamic> json) {
    final chainsJson = (json['chains'] as Map<String, dynamic>?) ?? const {};
    final limitsJson = (json['limits'] as Map<String, dynamic>?) ?? const {};

    return RemoteSwapConfig(
      chains: chainsJson.map(
        (k, v) => MapEntry(
          k,
          RemoteChainConfig.fromJson(v as Map<String, dynamic>),
        ),
      ),
      limits: RemoteLimits.fromJson(limitsJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'chains': chains.map((k, v) => MapEntry(k, v.toJson())),
        'limits': limits.toJson(),
      };

  /// Merges with the compile-time defaults so that any field missing from the
  /// backend response (or a future field the backend doesn't know yet) falls
  /// back to a known-good value rather than blowing up downstream.
  RemoteSwapConfig withDefaultsFallback() {
    final defaults = RemoteSwapConfig.fromDefaults();
    return RemoteSwapConfig(
      chains: {
        for (final key in kZeroxSupportedChains)
          key: chains[key] ?? defaults.chains[key]!,
      },
      limits: limits,
    );
  }
}

class RemoteChainConfig {
  final List<String> rpcs;
  final String feeRecipient;
  final List<String> allowedRouters;

  const RemoteChainConfig({
    required this.rpcs,
    required this.feeRecipient,
    required this.allowedRouters,
  });

  factory RemoteChainConfig.fromJson(Map<String, dynamic> json) =>
      RemoteChainConfig(
        rpcs: ((json['rpcs'] as List?) ?? const []).cast<String>(),
        feeRecipient: (json['feeRecipient'] as String?) ?? '',
        allowedRouters:
            ((json['allowedRouters'] as List?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'rpcs': rpcs,
        'feeRecipient': feeRecipient,
        'allowedRouters': allowedRouters,
      };
}

class RemoteLimits {
  final double largeAmountUsdThreshold;
  final int priceDriftBps;
  final int approveReceiptTimeoutSeconds;

  const RemoteLimits({
    required this.largeAmountUsdThreshold,
    required this.priceDriftBps,
    required this.approveReceiptTimeoutSeconds,
  });

  factory RemoteLimits.fromJson(Map<String, dynamic> json) => RemoteLimits(
        largeAmountUsdThreshold:
            (json['largeAmountUsdThreshold'] as num?)?.toDouble() ?? 10000,
        priceDriftBps: (json['priceDriftBps'] as int?) ?? 100,
        approveReceiptTimeoutSeconds:
            (json['approveReceiptTimeoutSeconds'] as int?) ?? 60,
      );

  Map<String, dynamic> toJson() => {
        'largeAmountUsdThreshold': largeAmountUsdThreshold,
        'priceDriftBps': priceDriftBps,
        'approveReceiptTimeoutSeconds': approveReceiptTimeoutSeconds,
      };
}
