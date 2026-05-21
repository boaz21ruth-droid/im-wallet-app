import 'package:get/get.dart';

import 'favorites_logic.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FavoritesLogic());
  }
}
