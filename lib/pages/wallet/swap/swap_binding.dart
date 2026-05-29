// lib/pages/wallet/swap/swap_binding.dart
import 'package:get/get.dart';

import '../../../services/wallet/swap/swap_config_service.dart';
import 'swap_logic.dart';

class SwapBinding extends Bindings {
  @override
  void dependencies() {
    // SwapConfigService is permanent — it holds the config used by both
    // SwapLogic (this page) and WalletLogic (for RPC override on every chain
    // refresh). Once registered, WalletLogic._refreshSwapConfig will hit it
    // on every unlock.
    if (!Get.isRegistered<SwapConfigService>()) {
      Get.put<SwapConfigService>(SwapConfigService(), permanent: true);
      Get.find<SwapConfigService>().loadFromStorage();
    }
    Get.lazyPut(() => SwapLogic());
  }
}
