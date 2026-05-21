import 'package:get/get.dart';

import 'calls_logic.dart';

class CallsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CallsLogic());
  }
}
