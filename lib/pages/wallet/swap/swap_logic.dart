// lib/pages/wallet/swap/swap_logic.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/evm_service.dart';
import '../../../services/wallet/swap/swap_config.dart';
import '../../../services/wallet/swap/swap_models.dart';
import '../../../services/wallet/swap/swap_provider.dart';
import '../../../services/wallet/swap/zerox_provider.dart';
import '../../../services/wallet/wallet_key.dart';
import '../wallet_logic.dart';

class SwapLogic extends GetxController {
  final WalletLogic wallet = Get.find<WalletLogic>();

  final swapChainKey = 'eth'.obs;
  final sellToken = Rxn<SwapToken>();
  final buyToken = Rxn<SwapToken>();
  final sellAmountText = ''.obs;
  final priceResult = Rxn<SwapPriceResult>();
  final isFetchingPrice = false.obs;
  final lastError = Rxn<SwapException>();
  final needsApproval = Rxn<bool>();
  final slippageBps = 50.obs;
  final providerId = 'zerox'.obs;

  late final Map<String, SwapProvider> providers = {
    'zerox': ZeroExProvider(),
  };

  Timer? _debounce;
  int _priceSeq = 0;

  SwapProvider get activeProvider => providers[providerId.value]!;

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
  }

  void selectBuyToken(SwapToken t) {
    buyToken.value = t;
    priceResult.value = null;
    _fetchPriceIfReady();
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
      // Cheap follow-up: one allowance RPC call (or instant for native).
      // TODO(task4): refresh needsApproval after successful approve
      await _refreshApprovalState();
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
    final svc = EvmService(config, chainKey);
    try {
      final allowance = await svc.getAllowance(
        owner: taker,
        spender: kZeroxAllowanceHolder,
        tokenContract: contract,
      );
      needsApproval.value = allowance < amt;
    } catch (_) {
      needsApproval.value = null;
    } finally {
      svc.dispose();
    }
  }

  /// Result of executeSwap. Carries the broadcast tx hash, or an error
  /// description for the result page.
  Future<SwapExecutionResult> executeSwap({required String password}) async {
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

    // Decrypt mnemonic → derive EVM key
    final svc = EvmService(config, chainKey);
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
      // Step 2: Approve if needed
      if (quote.approval != null) {
        final approval = quote.approval!;
        try {
          final approveTx = await svc.sendApprove(
            senderKey: evmKey,
            tokenContract: approval.tokenAddress,
            spender: approval.spender,
            amount: _maxUint256,
          );
          final ok = await svc.waitForReceipt(approveTx);
          if (!ok) {
            return SwapExecutionResult.failed('授权交易未确认，请稍后重试');
          }
        } catch (e) {
          return SwapExecutionResult.failed('授权失败: $e');
        }

        // Re-quote — calldata + buyAmount may shift after approve confirmed.
        try {
          quote = await activeProvider.getQuote(req);
        } on SwapException catch (e) {
          return SwapExecutionResult.failed('重新报价失败: ${e.message}');
        }
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
    } on ArgumentError {
      return const SwapExecutionResult.failed('报价数据无效');
    } catch (e) {
      return SwapExecutionResult.failed('Swap 失败: $e');
    } finally {
      svc.dispose();
    }
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
