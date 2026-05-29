// lib/pages/wallet/swap/swap_binding.dart
import 'package:get/get.dart';
import 'swap_logic.dart';

class SwapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SwapLogic());
  }
}
