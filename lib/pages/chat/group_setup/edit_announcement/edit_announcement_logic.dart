import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../group_setup_logic.dart';

class EditAnnouncementLogic extends GetxController {
  final groupSetupLogic = Get.find<GroupSetupLogic>();
  late TextEditingController inputCtrl;

  @override
  void onInit() {
    inputCtrl = TextEditingController(
      text: groupSetupLogic.groupInfo.value.notification ?? '',
    );
    super.onInit();
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    super.onClose();
  }

  String get groupID => groupSetupLogic.groupInfo.value.groupID;

  void save() async {
    await LoadingView.singleton.wrap(asyncFunction: () async {
      await OpenIM.iMManager.groupManager.setGroupInfo(
        GroupInfo(groupID: groupID, notification: inputCtrl.text.trim()),
      );
    });
    IMViews.showToast(StrRes.setSuccessfully);
    Get.back();
  }
}
