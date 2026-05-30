// lib/pages/wallet/swap/swap_logic.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import '../../../services/totp_service.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/evm_service.dart';
import '../../../services/wallet/swap/swap_config.dart';
import '../../../services/wallet/swap/remote_swap_config.dart';
import '../../../services/wallet/swap/swap_config_service.dart';
import '../../../services/wallet/swap/swap_models.dart';
import '../../../services/wallet/swap/swap_provider.dart';
import '../../../services/wallet/swap/backend_quote_provider.dart';
import '../../../services/wallet/wallet_models.dart';
import '../../../services/wallet/wallet_key.dart';
import '../send/totp_verify_dialog.dart';
import '../wallet_logic.dart';

class SwapLogic extends GetxController {
  final WalletLogic wallet = Get.find<WalletLogic>();

  final swapChainKey = 'eth'.obs;
  final sellToken = Rxn<SwapToken>();
  final buyToken = Rxn<SwapToken>();
  final sellAmountText = ''.obs;
  final priceResult = Rxn<SwapPriceResult>();
  /// Ranked per-aggregator quotes (best first) for the comparison UI.
  final allPrices = <SwapPriceResult>[].obs;
  final isFetchingPrice = false.obs;
  final lastError = Rxn<SwapException>();
  final needsApproval = Rxn<bool>();
  final slippageBps = 50.obs;
  // 'best' = server-side aggregated best quote across all configured aggregators.
  final providerId = 'best'.obs;

  /// Whether the backend has supplied a 0x API key. Drives the "未配置" banner.
  /// The key is never baked into the app — it comes from /wallet/swap_config.
  final swapConfigured = false.obs;

  late final Map<String, SwapProvider> providers = {
    'best': BackendQuoteProvider(),
  };

  Timer? _debounce;
  int _priceSeq = 0;

  /// Cached gas price (in wei) per chain — refreshed on a successful price
  /// fetch so the pre-flight "Gas 不足" check has something to multiply
  /// `gasEstimate` against. Conservative: stale prices are still close to
  /// reality for a few seconds.
  final gasPriceByChain = <String, BigInt>{}.obs;

  SwapProvider get activeProvider => providers[providerId.value]!;

  RemoteSwapConfig get _config => SwapConfigService.to.current;

  @override
  void onInit() {
    super.onInit();
    // Swap is "configured" when the backend delivered swap config with at least
    // one chain. Aggregator keys live server-side, so the client can no longer
    // gate on a key; it gates on whether the backend served usable config.
    swapConfigured.value = _config.chains.isNotEmpty;
    SwapConfigService.to.fetchAndCache().then((cfg) {
      if (cfg != null) swapConfigured.value = cfg.chains.isNotEmpty;
    });
  }

  String get takerAddress {
    final acc = wallet.selectedAccount.value;
    if (acc == null) return '';
    return acc.addresses[swapChainKey.value] ?? '';
  }

  /// sellAmount in raw BigInt units (10^decimals). Returns zero on parse failure
  /// or when sellToken not set.
  BigInt get sellAmountRaw {
    final t = sellToken.value;
    if (t == null) return BigInt.zero;
    return parseDecimalAmount(sellAmountText.value, t.decimals);
  }

  /// Parses a decimal string into a raw BigInt amount using string math
  /// (no doubles), so 18-decimal precision is preserved. Returns BigInt.zero
  /// on any parse failure or non-positive value.
  ///
  /// Examples:
  ///   parseDecimalAmount('0.1', 18)        -> 100000000000000000
  ///   parseDecimalAmount('1.123456789', 6) -> 1123456  (truncates extra digits)
  ///   parseDecimalAmount('', 18)           -> 0
  @visibleForTesting
  static BigInt parseDecimalAmount(String text, int decimals) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return BigInt.zero;
    // Only digits and at most one '.'
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(trimmed)) return BigInt.zero;
    final parts = trimmed.split('.');
    if (parts.length > 2) return BigInt.zero;
    final intPart = parts[0];
    final fracPart = parts.length == 2 ? parts[1] : '';
    if (intPart.isEmpty && fracPart.isEmpty) return BigInt.zero;
    String paddedFrac;
    if (fracPart.length >= decimals) {
      paddedFrac = fracPart.substring(0, decimals);
    } else {
      paddedFrac = fracPart.padRight(decimals, '0');
    }
    final combined = '${intPart.isEmpty ? '0' : intPart}$paddedFrac';
    final stripped = combined.replaceFirst(RegExp(r'^0+'), '');
    if (stripped.isEmpty) return BigInt.zero;
    try {
      final v = BigInt.parse(stripped);
      return v > BigInt.zero ? v : BigInt.zero;
    } catch (_) {
      return BigInt.zero;
    }
  }

  void onAmountInput(String text) {
    sellAmountText.value = text;
    _debounce?.cancel();
    if (sellAmountRaw == BigInt.zero) {
      priceResult.value = null;
      lastError.value = null;
      needsApproval.value = null;
      _priceSeq++;
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 400), _fetchPriceIfReady);
  }

  void invertTokens() {
    final s = sellToken.value;
    final b = buyToken.value;
    sellToken.value = b;
    buyToken.value = s;
    sellAmountText.value = '';
    priceResult.value = null;
    lastError.value = null;
    needsApproval.value = null;
  }

  void switchChain(String chainKey) {
    if (!chains.containsKey(chainKey)) return;
    swapChainKey.value = chainKey;
    sellToken.value = null;
    buyToken.value = null;
    sellAmountText.value = '';
    priceResult.value = null;
    lastError.value = null;
    needsApproval.value = null;
  }

  void selectSellToken(SwapToken t) {
    sellToken.value = t;
    priceResult.value = null;
    _fetchPriceIfReady();
    unawaited(_validateCustomTokenDecimals(t, isSell: true));
  }

  void selectBuyToken(SwapToken t) {
    buyToken.value = t;
    priceResult.value = null;
    _fetchPriceIfReady();
    unawaited(_validateCustomTokenDecimals(t, isSell: false));
  }

  /// For user-added custom tokens (not in `ChainConfig.builtinTokens`), verify
  /// the on-chain `decimals()` matches what's stored locally. On mismatch:
  /// revert the selection and surface a toast. Native tokens and builtin ones
  /// are trusted unconditionally.
  Future<void> _validateCustomTokenDecimals(SwapToken t,
      {required bool isSell}) async {
    final contract = t.contractAddress;
    if (contract == null) return; // native token, no contract to query
    final chainCfg = chains[t.chainKey];
    if (chainCfg == null || chainCfg.isTron) return;
    // Skip when the token is one of the chain's builtins — those decimals are
    // hand-curated and don't need round-tripping.
    final builtin = chainCfg.builtinTokens.any(
      (b) => b.contractAddress.toLowerCase() == contract.toLowerCase(),
    );
    if (builtin) return;

    final svc = EvmService(
      chainCfg,
      t.chainKey,
      rpcsOverride: _swapConfigRpcs(t.chainKey),
    );
    try {
      final onChain = await svc.getDecimals(contract);
      if (onChain != t.decimals) {
        // Revert the just-set selection if the user is still on this token.
        if (isSell && sellToken.value == t) {
          sellToken.value = null;
          priceResult.value = null;
          needsApproval.value = null;
        } else if (!isSell && buyToken.value == t) {
          buyToken.value = null;
          priceResult.value = null;
        }
        EasyLoading.showToast(
          '代币 decimals 不匹配（链上 $onChain, 本地 ${t.decimals}）—— 请删除后重新添加',
        );
      }
    } catch (_) {
      // RPC failure: don't block the user from continuing. They'll get a clear
      // error from the actual swap path if the decimals really are wrong.
    } finally {
      svc.dispose();
    }
  }

  /// Returns the RPC list the backend config wants for `chainKey`, or null
  /// when the config doesn't have one (fall back to hardcoded `chains[k].rpcs`).
  List<String>? _swapConfigRpcs(String chainKey) {
    final rpcs = _config.chains[chainKey]?.rpcs;
    return (rpcs == null || rpcs.isEmpty) ? null : rpcs;
  }

  /// Held balance for `t` on the current chain. Returns null when the user
  /// holds none (or the balance hasn't loaded yet — caller treats this as
  /// "insufficient" defensively).
  AssetBalance? heldBalance(SwapToken t) {
    final chainBalances = wallet.balancesForChain(t.chainKey);
    for (final b in chainBalances) {
      if (b.symbol == t.symbol && b.contractAddress == t.contractAddress) {
        return b;
      }
    }
    return null;
  }

  /// Native balance for the current swap chain — used to determine whether
  /// the user has enough to pay gas.
  AssetBalance? nativeBalanceForChain(String chainKey) {
    final cfg = chains[chainKey];
    if (cfg == null) return null;
    for (final b in wallet.balancesForChain(chainKey)) {
      if (b.isNative) return b;
    }
    return null;
  }

  /// Estimated gas cost in native-wei units for the current price quote.
  /// `null` when there's no quote yet or no gas price cached.
  BigInt? get estGasInWei {
    final pr = priceResult.value;
    if (pr?.gasEstimate == null) return null;
    final gp = gasPriceByChain[swapChainKey.value];
    if (gp == null) return null;
    return pr!.gasEstimate! * gp;
  }

  void setSlippageBps(int bps) {
    slippageBps.value = bps;
    _fetchPriceIfReady();
  }

  Future<void> _fetchPriceIfReady() async {
    final sell = sellToken.value;
    final buy = buyToken.value;
    final amt = sellAmountRaw;
    final taker = takerAddress;
    if (sell == null || buy == null || amt == BigInt.zero || taker.isEmpty) {
      priceResult.value = null;
      return;
    }
    if (sell == buy) {
      priceResult.value = null;
      return;
    }
    final req = SwapQuoteRequest(
      chainKey: swapChainKey.value,
      sellToken: sell,
      buyToken: buy,
      sellAmount: amt,
      takerAddress: taker,
      slippageBps: slippageBps.value,
    );
    final seq = ++_priceSeq;
    isFetchingPrice.value = true;
    lastError.value = null;
    try {
      final r = await activeProvider.getPrice(req);
      if (seq != _priceSeq) return; // stale; another call superseded
      priceResult.value = r;
      final ap = activeProvider;
      allPrices.assignAll(
          ap is BackendQuoteProvider ? ap.lastComparison : const []);
      // Cheap follow-up: one allowance RPC call (or instant for native) plus
      // a gas-price snapshot for the pre-flight "Gas 不足" check.
      // TODO(task4): refresh needsApproval after successful approve
      await _refreshApprovalState();
      unawaited(_refreshGasPrice(req.chainKey));
    } on SwapException catch (e) {
      if (seq != _priceSeq) return;
      lastError.value = e;
      priceResult.value = null;
    } finally {
      if (seq == _priceSeq) isFetchingPrice.value = false;
    }
  }

  /// Determines whether the user must approve the swap router to spend
  /// the sell token before [executeSwap] can proceed. Native sells skip the
  /// allowance check (no approval needed). Errors set `needsApproval` to null.
  Future<void> _refreshApprovalState() async {
    final sell = sellToken.value;
    final amt = sellAmountRaw;
    final taker = takerAddress;
    final chainKey = swapChainKey.value;
    final config = chains[chainKey];
    if (sell == null || amt == BigInt.zero || taker.isEmpty || config == null) {
      needsApproval.value = null;
      return;
    }
    if (sell.isNative) {
      needsApproval.value = false;
      return;
    }
    final contract = sell.contractAddress;
    if (contract == null) {
      needsApproval.value = null;
      return;
    }
    // Use the first configured router as the allowance spender. Defaults to
    // the well-known 0x AllowanceHolder when backend config is missing.
    final spender = _config.chains[chainKey]?.allowedRouters.firstOrNull ??
        kZeroxAllowanceHolder;
    final svc = EvmService(
      config,
      chainKey,
      rpcsOverride: _swapConfigRpcs(chainKey),
    );
    try {
      final allowance = await svc.getAllowance(
        owner: taker,
        spender: spender,
        tokenContract: contract,
      );
      needsApproval.value = allowance < amt;
    } catch (_) {
      needsApproval.value = null;
    } finally {
      svc.dispose();
    }
  }

  /// Fetches and caches the current gas price for `chainKey` so the
  /// pre-flight "Gas 不足" check has a multiplier for `gasEstimate`.
  Future<void> _refreshGasPrice(String chainKey) async {
    final cfg = chains[chainKey];
    if (cfg == null || cfg.isTron) return;
    final svc = EvmService(
      cfg,
      chainKey,
      rpcsOverride: _swapConfigRpcs(chainKey),
    );
    try {
      final gp = await svc.getGasPrice();
      gasPriceByChain[chainKey] = gp;
    } catch (_) {
      // Stale cache is fine; pre-flight check will just skip when empty.
    } finally {
      svc.dispose();
    }
  }

  /// Result of executeSwap. Carries the broadcast tx hash, or an error
  /// description for the result page.
  Future<SwapExecutionResult> executeSwap({required String password}) async {
    // Route guard: capture the active route name. If the user pops SwapView
    // mid-flight (system back, etc.), every later step bails so we don't show
    // a TOTP dialog / result page over an unrelated screen.
    final entryRoute = Get.routing.current;
    bool routeStillActive() => Get.routing.current == entryRoute;

    final sell = sellToken.value;
    final buy = buyToken.value;
    final amt = sellAmountRaw;
    final taker = takerAddress;
    if (sell == null || buy == null || amt == BigInt.zero || taker.isEmpty) {
      return const SwapExecutionResult.failed('内部错误：缺少参数');
    }
    final account = wallet.selectedAccount.value;
    if (account == null) {
      return const SwapExecutionResult.failed('未选择账户');
    }
    final chainKey = swapChainKey.value;
    final config = chains[chainKey];
    if (config == null) {
      return const SwapExecutionResult.failed('链配置缺失');
    }

    // Step 1: hard quote
    final req = SwapQuoteRequest(
      chainKey: chainKey,
      sellToken: sell,
      buyToken: buy,
      sellAmount: amt,
      takerAddress: taker,
      slippageBps: slippageBps.value,
    );
    SwapQuote quote;
    try {
      quote = await activeProvider.getQuote(req);
    } on SwapException catch (e) {
      return SwapExecutionResult.failed('报价失败: ${e.message}');
    }
    if (!routeStillActive()) {
      return const SwapExecutionResult.failed('已取消（页面已切换）');
    }

    // Decrypt mnemonic → derive EVM key
    final svc = EvmService(
      config,
      chainKey,
      rpcsOverride: _swapConfigRpcs(chainKey),
    );
    EthPrivateKey? evmKey;
    try {
      evmKey = await wallet.vault.withMnemonic(password, (mBytes) async {
        final seed = WalletKey.mnemonicToSeed(mBytes);
        try {
          return WalletKey.deriveEVMKey(seed, account.index);
        } finally {
          seed.fillRange(0, seed.length, 0);
        }
      });
    } catch (e) {
      svc.dispose();
      return SwapExecutionResult.failed('密码错误或解密失败');
    }
    if (evmKey == null) {
      svc.dispose();
      return const SwapExecutionResult.failed('无法派生密钥');
    }

    try {
      // Step 2: TOTP gate (gates approve + swap)
      final totpEnabled = await TotpService.status();
      if (!routeStillActive()) {
        return const SwapExecutionResult.failed('已取消（页面已切换）');
      }
      if (totpEnabled) {
        final ctx = Get.context;
        if (ctx == null) return const SwapExecutionResult.failed('上下文丢失');
        // ignore: use_build_context_synchronously
        final ok = await showTotpVerifyDialog(ctx);
        if (!ok) return const SwapExecutionResult.failed('已取消');
        if (!routeStillActive()) {
          return const SwapExecutionResult.failed('已取消（页面已切换）');
        }
      }

      // Step 2.2: Large-amount confirmation. Threshold comes from backend
      // config so it can be tuned without an app release.
      final usdValue = _estimatedUsdValue(sell, amt);
      if (usdValue != null &&
          usdValue > _config.limits.largeAmountUsdThreshold) {
        final ctx = Get.context;
        if (ctx == null) return const SwapExecutionResult.failed('上下文丢失');
        final accepted = await _confirmLargeAmount(
          // ignore: use_build_context_synchronously
          ctx,
          usdValue: usdValue,
          sell: sell,
          buy: buy,
          sellAmount: amt,
          buyAmount: quote.buyAmount,
        );
        if (!accepted) {
          return const SwapExecutionResult.failed('已取消（大额确认）');
        }
        if (!routeStillActive()) {
          return const SwapExecutionResult.failed('已取消（页面已切换）');
        }
      }

      // Step 2.5: Approve if needed. A provider may surface approval info
      // unconditionally for ERC20 sells (e.g. 1inch can't tell us the live
      // allowance), so re-check the on-chain allowance against the winning
      // provider's spender and skip a redundant approve when already covered.
      if (quote.approval != null) {
        final approval = quote.approval!;
        var approvalNeeded = true;
        try {
          final current = await svc.getAllowance(
            owner: taker,
            spender: approval.spender,
            tokenContract: approval.tokenAddress,
          );
          approvalNeeded = current < approval.requiredAmount;
        } catch (_) {
          // If the allowance check fails, fall through and approve to be safe.
        }
        if (approvalNeeded) {
        try {
          final approveTx = await svc.sendApprove(
            senderKey: evmKey,
            tokenContract: approval.tokenAddress,
            spender: approval.spender,
            amount: _maxUint256,
          );
          final ok = await svc.waitForReceipt(
            approveTx,
            timeout: Duration(
              seconds: _config.limits.approveReceiptTimeoutSeconds,
            ),
          );
          if (!ok) {
            return SwapExecutionResult.failed('授权交易未确认，请稍后重试');
          }
        } catch (e) {
          return SwapExecutionResult.failed('授权失败: $e');
        }
        if (!routeStillActive()) {
          return const SwapExecutionResult.failed('已取消（页面已切换）');
        }

        // Re-quote — calldata + buyAmount may shift after approve confirmed.
        try {
          quote = await activeProvider.getQuote(req);
        } on SwapException catch (e) {
          return SwapExecutionResult.failed('重新报价失败: ${e.message}');
        }
        } // approvalNeeded
      }

      // Step 2.7: price-drift check. Threshold from backend config (default 1%).
      try {
        final fresh = await activeProvider.getQuote(req);
        if (!routeStillActive()) {
          return const SwapExecutionResult.failed('已取消（页面已切换）');
        }
        final drift = (fresh.buyAmount - quote.buyAmount).abs();
        final driftBps = BigInt.from(_config.limits.priceDriftBps);
        final threshold =
            quote.buyAmount * driftBps ~/ BigInt.from(10000);
        if (drift > threshold) {
          final ctx = Get.context;
          if (ctx == null) return const SwapExecutionResult.failed('上下文丢失');
          final accepted = await _confirmPriceDrift(
              // ignore: use_build_context_synchronously
              ctx,
              oldAmount: quote.buyAmount,
              newAmount: fresh.buyAmount);
          if (!accepted) return const SwapExecutionResult.failed('已取消（价格漂移）');
          if (!routeStillActive()) {
            return const SwapExecutionResult.failed('已取消（页面已切换）');
          }
        }
        quote = fresh;
      } on SwapException catch (e) {
        return SwapExecutionResult.failed('重新报价失败: ${e.message}');
      }

      // Step 3: send swap calldata
      final txHash = await svc.sendRaw(
        senderKey: evmKey,
        to: quote.to,
        dataHex: quote.data,
        value: quote.value,
        gasLimit: quote.gas,
        gasPrice: quote.gasPrice,
      );
      // Don't await final confirmation — return immediately.
      wallet.refreshBalances();
      return SwapExecutionResult.success(
        txHash: txHash,
        chainKey: chainKey,
      );
    } on SwapException catch (e) {
      return SwapExecutionResult.failed('Swap 失败: ${e.message}');
    } on ArgumentError {
      return const SwapExecutionResult.failed('报价数据无效');
    } catch (e) {
      return SwapExecutionResult.failed('Swap 失败: $e');
    } finally {
      svc.dispose();
    }
  }

  /// Returns the USD-equivalent value of `amount` of `sell`, or null when no
  /// price feed is loaded for that token.
  double? _estimatedUsdValue(SwapToken sell, BigInt amount) {
    final price = wallet.coinPrices[sell.symbol]?.price;
    if (price == null || price <= 0) return null;
    final divisor = BigInt.from(10).pow(sell.decimals);
    if (divisor == BigInt.zero) return null;
    final whole = amount ~/ divisor;
    final frac = amount - whole * divisor;
    // Convert via a fixed-point division so we don't blow precision on big
    // BigInts; the multiplier scales fractional to 6 decimal places.
    const scale = 1000000;
    final fracScaled =
        (frac * BigInt.from(scale) ~/ divisor).toInt() / scale;
    final tokenAmount = whole.toDouble() + fracScaled;
    return tokenAmount * price;
  }

  Future<bool> _confirmLargeAmount(
    BuildContext ctx, {
    required double usdValue,
    required SwapToken sell,
    required SwapToken buy,
    required BigInt sellAmount,
    required BigInt buyAmount,
  }) async {
    String fmt(BigInt v, int decimals) {
      final d = BigInt.from(10).pow(decimals);
      final whole = v ~/ d;
      final frac =
          (v - whole * d).toString().padLeft(decimals, '0');
      return '$whole.${frac.substring(0, frac.length.clamp(0, 6))}';
    }

    final result = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('大额交易确认'),
        content: Text(
          '本笔交易约值 \$${usdValue.toStringAsFixed(2)}\n\n'
          '支付: ${fmt(sellAmount, sell.decimals)} ${sell.symbol}\n'
          '获得: 约 ${fmt(buyAmount, buy.decimals)} ${buy.symbol}\n\n'
          '请再次确认。',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('继续')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmPriceDrift(BuildContext ctx,
      {required BigInt oldAmount, required BigInt newAmount}) async {
    final buy = buyToken.value;
    if (buy == null) return false;
    String fmt(BigInt v) {
      final d = BigInt.from(10).pow(buy.decimals);
      final whole = v ~/ d;
      final frac = (v - whole * d).toString().padLeft(buy.decimals, '0');
      return '$whole.${frac.substring(0, frac.length.clamp(0, 6))}';
    }
    final result = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('价格已变动'),
        content: Text(
            '原报价: ${fmt(oldAmount)} ${buy.symbol}\n新报价: ${fmt(newAmount)} ${buy.symbol}\n是否按新价继续？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('继续')),
        ],
      ),
    );
    return result ?? false;
  }

  static final BigInt _maxUint256 =
      BigInt.parse('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', radix: 16);

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}

class SwapExecutionResult {
  final bool ok;
  final String? txHash;
  final String? chainKey;
  final String? error;

  const SwapExecutionResult.success({required String this.txHash, required String this.chainKey})
      : ok = true, error = null;

  const SwapExecutionResult.failed(String this.error)
      : ok = false, txHash = null, chainKey = null;
}
