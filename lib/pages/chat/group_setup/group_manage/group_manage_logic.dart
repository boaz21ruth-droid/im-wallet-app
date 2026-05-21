import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim/pages/chat/group_setup/group_setup_logic.dart';
import 'package:openim_common/openim_common.dart';

import '../../../../routes/app_navigator.dart';
import '../group_member_list/group_member_list_logic.dart';

class GroupManageLogic extends GetxController {
  final groupSetupLogic = Get.find<GroupSetupLogic>();
  late StreamSubscription _mISub;

  Rx<GroupInfo> get groupInfo => groupSetupLogic.groupInfo;
  bool get isOwner => groupSetupLogic.isOwner;
  bool get isOwnerOrAdmin => groupSetupLogic.isOwnerOrAdmin;

  final adminList = <GroupMembersInfo>[].obs;

  @override
  void onInit() {
    final imLogic = groupSetupLogic.imLogic;
    _mISub = imLogic.memberInfoChangedSubject.listen((e) {
      if (e.groupID == groupInfo.value.groupID) _refreshAdminEntry(e);
    });
    super.onInit();
  }

  @override
  void onReady() {
    _loadAdminList();
    super.onReady();
  }

  @override
  void onClose() {
    _mISub.cancel();
    super.onClose();
  }

  Future<void> _loadAdminList() async {
    final list = await OpenIM.iMManager.groupManager.getGroupMemberList(
      groupID: groupInfo.value.groupID,
      filter: 2,
      count: 100,
      offset: 0,
    );
    adminList.assignAll(list);
  }

  void _refreshAdminEntry(GroupMembersInfo updated) {
    final idx = adminList.indexWhere((m) => m.userID == updated.userID);
    if (updated.roleLevel == GroupRoleLevel.admin) {
      if (idx < 0) adminList.add(updated);
    } else {
      if (idx >= 0) adminList.removeAt(idx);
    }
  }

  void transferGroupOwnerRight() async {
    var result = await AppNavigator.startGroupMemberList(
      groupInfo: groupInfo.value,
      opType: GroupMemberOpType.transferRight,
    );
    if (result is GroupMembersInfo) {
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.groupManager.transferGroupOwner(
          groupID: groupInfo.value.groupID,
          userID: result.userID!,
        ),
      );
      groupInfo.update((val) {
        val?.ownerUserID = result.userID;
      });
      Get.back();
    }
  }

  void setAdmin() async {
    final result = await AppNavigator.startGroupMemberList(
      groupInfo: groupInfo.value,
      opType: GroupMemberOpType.setAdmin,
    );
    if (result is GroupMembersInfo) {
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.groupManager.setGroupMemberInfo(
          groupMembersInfo: SetGroupMemberInfo(
            groupID: groupInfo.value.groupID,
            userID: result.userID!,
            roleLevel: GroupRoleLevel.admin,
          ),
        ),
      );
      await _loadAdminList();
    }
  }

  void removeAdmin(GroupMembersInfo member) async {
    final confirm = await Get.dialog(CustomDialog(
      title: '确认撤销 ${member.nickname} 的管理员权限？',
    ));
    if (confirm != true) return;
    await LoadingView.singleton.wrap(
      asyncFunction: () => OpenIM.iMManager.groupManager.setGroupMemberInfo(
        groupMembersInfo: SetGroupMemberInfo(
          groupID: groupInfo.value.groupID,
          userID: member.userID!,
          roleLevel: GroupRoleLevel.member,
        ),
      ),
    );
    await _loadAdminList();
  }

  void muteUser() async {
    final result = await AppNavigator.startGroupMemberList(
      groupInfo: groupInfo.value,
      opType: GroupMemberOpType.mute,
    );
    if (result is! GroupMembersInfo) return;
    final seconds = await _showMuteDurationDialog();
    if (seconds == null) return;
    await LoadingView.singleton.wrap(
      asyncFunction: () => OpenIM.iMManager.groupManager.changeGroupMemberMute(
        groupID: groupInfo.value.groupID,
        userID: result.userID!,
        seconds: seconds,
      ),
    );
  }

  void kickUser() async {
    final result = await AppNavigator.startGroupMemberList(
      groupInfo: groupInfo.value,
      opType: GroupMemberOpType.del,
    );
    if (result is List<GroupMembersInfo> && result.isNotEmpty) {
      await LoadingView.singleton.wrap(
        asyncFunction: () => OpenIM.iMManager.groupManager.kickGroupMember(
          groupID: groupInfo.value.groupID,
          userIDList: result.map((e) => e.userID!).toList(),
          reason: '',
        ),
      );
    }
  }

  Future<int?> _showMuteDurationDialog() => Get.dialog<int>(
        AlertDialog(
          title: const Text('选择禁言时长'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('10 分钟'), onTap: () => Get.back(result: 600)),
              ListTile(title: const Text('1 小时'), onTap: () => Get.back(result: 3600)),
              ListTile(title: const Text('1 天'), onTap: () => Get.back(result: 86400)),
              ListTile(title: const Text('永久'), onTap: () => Get.back(result: 2592000)),
            ],
          ),
        ),
      );
}
