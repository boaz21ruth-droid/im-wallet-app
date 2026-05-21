import 'package:get/get.dart';
import 'group_files_logic.dart';

class GroupFilesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupFilesLogic>(() => GroupFilesLogic());
  }
}
