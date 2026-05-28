import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../group_profile_panel/group_profile_panel_logic.dart';

class SendVerificationApplicationLogic extends GetxController {
  final inputCtrl = TextEditingController();
  String? userID;
  String? groupID;
  JoinGroupMethod? joinGroupMethod;

  bool get isEnterGroup => groupID != null;

  bool get isAddFriend => userID != null;

  @override
  void onInit() {
    userID = Get.arguments['userID'];
    groupID = Get.arguments['groupID'];
    joinGroupMethod = Get.arguments['joinGroupMethod'];
    super.onInit();
  }

  void send() async {
    if (isAddFriend) {
      _applyAddFriend();
    } else if (isEnterGroup) {
      _applyEnterGroup();
    }
  }

  Future<void> _applyAddFriend() async {
    try {
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.friendshipManager.addFriend(
          userID: userID!,
          reason: inputCtrl.text.trim(),
        ),
      );
      Get.back();
      IMViews.showToast(StrRes.sendSuccessfully);
    } catch (e) {
      if (e is PlatformException) {
        if (e.code == '${SDKErrorCode.refuseToAddFriends}') {
          IMViews.showToast(StrRes.canNotAddFriends);
          return;
        }
      }
      IMViews.showToast(StrRes.sendFailed);
    }
  }

  void _applyEnterGroup() {
    LoadingView.singleton
        .wrap(
          asyncFunction: () => OpenIM.iMManager.groupManager.joinGroup(
            groupID: groupID!,
            reason: inputCtrl.text.trim(),
            joinSource: joinGroupMethod == JoinGroupMethod.qrcode ? 4 : 3,
          ),
        )
        .then((value) => IMViews.showToast(StrRes.sendSuccessfully))
        .then((value) => Get.back())
        .catchError((e) => IMViews.showToast(StrRes.sendFailed));
  }
}
