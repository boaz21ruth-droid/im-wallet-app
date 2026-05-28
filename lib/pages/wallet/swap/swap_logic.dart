// lib/pages/wallet/swap/swap_logic.dart
import 'package:get/get.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/swap/swap_models.dart';
import '../wallet_logic.dart';

class SwapLogic extends GetxController {
  final WalletLogic _wallet = Get.find<WalletLogic>();

  /// Independent chain selection — does NOT mutate WalletLogic.selectedChainKey.
  final swapChainKey = 'eth'.obs;
  final sellToken = Rxn<SwapToken>();
  final buyToken = Rxn<SwapToken>();
  final sellAmountText = ''.obs;        // raw user input
  final priceResult = Rxn<SwapPriceResult>();
  final isFetchingPrice = false.obs;
  final lastError = Rxn<SwapException>();

  /// 50 = 0.5% — default per spec §1.
  final slippageBps = 50.obs;

  /// Which provider the user has selected. MVP: always 'zerox'.
  final providerId = 'zerox'.obs;

  WalletLogic get wallet => _wallet;

  String get takerAddress {
    final acc = _wallet.selectedAccount.value;
    if (acc == null) return '';
    return acc.addresses[swapChainKey.value] ?? '';
  }

  /// Swap From/To. Resets amount.
  void invertTokens() {
    final s = sellToken.value;
    final b = buyToken.value;
    sellToken.value = b;
    buyToken.value = s;
    sellAmountText.value = '';
    priceResult.value = null;
  }

  /// Switch active chain. Resets tokens + amount.
  void switchChain(String chainKey) {
    if (!chains.containsKey(chainKey)) return;
    swapChainKey.value = chainKey;
    sellToken.value = null;
    buyToken.value = null;
    sellAmountText.value = '';
    priceResult.value = null;
  }
}
