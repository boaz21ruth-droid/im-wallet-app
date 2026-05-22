import 'package:get/get.dart';

import 'wallet_logic.dart';

class WalletBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WalletLogic());
  }
}
