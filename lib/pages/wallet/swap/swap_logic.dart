// lib/pages/wallet/swap/swap_logic.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/swap/swap_models.dart';
import '../../../services/wallet/swap/swap_provider.dart';
import '../../../services/wallet/swap/zerox_provider.dart';
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
    final txt = sellAmountText.value;
    final dbl = double.tryParse(txt);
    if (dbl == null || dbl <= 0) return BigInt.zero;
    return BigInt.from(dbl * BigInt.from(10).pow(t.decimals).toDouble());
  }

  void onAmountInput(String text) {
    sellAmountText.value = text;
    _debounce?.cancel();
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
  }

  void switchChain(String chainKey) {
    if (!chains.containsKey(chainKey)) return;
    swapChainKey.value = chainKey;
    sellToken.value = null;
    buyToken.value = null;
    sellAmountText.value = '';
    priceResult.value = null;
    lastError.value = null;
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
    } on SwapException catch (e) {
      if (seq != _priceSeq) return;
      lastError.value = e;
      priceResult.value = null;
    } finally {
      if (seq == _priceSeq) isFetchingPrice.value = false;
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
