// lib/services/wallet/swap/swap_config.dart

/// 0x Swap API v2 key. Injected at compile time via:
///   fvm flutter run --dart-define=ZEROX_API_KEY=xxx
/// Empty string in non-prod builds; the UI shows a "未配置" banner when empty.
const String kZeroxApiKey =
    String.fromEnvironment('ZEROX_API_KEY', defaultValue: '');

/// Platform fee in basis points, applied via 0x `swapFeeBps`.
const int kSwapFeeBps = 30; // 0.30%

/// Per-chain fee recipient addresses. EMPTY = no fee for that chain.
/// Operations team supplies these before production launch.
const Map<String, String> kFeeRecipients = {
  'eth': '',
  'bsc': '',
  'polygon': '',
  'arbitrum': '',
  'optimism': '',
};

/// 0x AllowanceHolder contract — same address on every EVM chain. This is the
/// `spender` users approve ERC20 to. The /quote response also returns this in
/// `issues.allowance.spender`; we use the response value for safety and only
/// fall back to this constant for the static UI/tests.
const String kZeroxAllowanceHolder =
    '0x0000000000001fF3684f28c67538d4D072C22734';

/// EVM chain keys supported by 0x v2 in this app. Must be a subset of
/// `chains` in `chain_config.dart`. Drives Provider.supportsChain().
const List<String> kZeroxSupportedChains = [
  'eth', 'bsc', 'polygon', 'arbitrum', 'optimism',
];

/// Native-asset sentinel address used by 0x (and most aggregators).
const String kNativeTokenSentinel =
    '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
