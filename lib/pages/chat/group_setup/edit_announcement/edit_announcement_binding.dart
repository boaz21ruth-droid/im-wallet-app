import 'package:get/get.dart';

import 'edit_announcement_logic.dart';

class EditAnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditAnnouncementLogic());
  }
}
