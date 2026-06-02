import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:get/get.dart';
import 'package:openim/routes/app_navigator.dart';
import 'package:openim_common/openim_common.dart';

import '../../../core/controller/im_controller.dart';
import '../../../services/totp_service.dart';
import 'totp_disable_view.dart';
import 'totp_setup_view.dart';

class AccountSetupLogic extends GetxController {
  final imLogic = Get.find<IMController>();
  final curLanguage = "".obs;
  final totpEnabled = false.obs;
  final lockEnabled = false.obs;
  final biometricEnabled = false.obs;

  @override
  void onReady() {
    _updateLanguage();
    super.onReady();
  }

  @override
  void onInit() {
    _queryMyFullInfo();
    refreshTotpStatus();
    _refreshLockState();
    super.onInit();
  }

  void _refreshLockState() {
    lockEnabled.value = DataSp.getLockScreenPassword() != null;
    biometricEnabled.value = DataSp.isEnabledBiometric() == true;
  }

  void _queryMyFullInfo() async {
    final data = await LoadingView.singleton.wrap(
      asyncFunction: () => Apis.queryMyFullInfo(),
    );
    if (data is UserFullInfo) {
      final userInfo = UserFullInfo.fromJson(data.toJson());
      imLogic.userInfo.update((val) {
        val?.allowAddFriend = userInfo.allowAddFriend;
        val?.allowBeep = userInfo.allowBeep;
        val?.allowVibration = userInfo.allowVibration;
      });
    }
  }

  Future<void> refreshTotpStatus() async {
    totpEnabled.value = await TotpService.status();
  }

  Future<void> toggleTotp() async {
    final changed = totpEnabled.value
        ? await Get.to<bool>(() => const TotpDisablePage())
        : await Get.to<bool>(() => const TotpSetupPage());
    if (changed == true) {
      await refreshTotpStatus();
    }
  }

  Future<void> setupAppLock() async {
    final ctx = Get.context!;
    if (!lockEnabled.value) {
      await screenLockCreate(
        context: ctx,
        title: const Text('设置 PIN 码'),
        confirmTitle: const Text('再次确认 PIN 码'),
        canCancel: true,
        onCancelled: () => Navigator.of(ctx).pop(),
        onConfirmed: (pin) async {
          await DataSp.putLockScreenPassword(pin);
          Navigator.of(ctx).pop();
        },
      );
      _refreshLockState();
      return;
    }

    // PIN already set — ask what to do
    final choice = await showDialog<String>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('应用锁定'),
        content: const Text('当前应用锁定已开启'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, 'change'),
            child: const Text('修改 PIN 码'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, 'disable'),
            child: Text('关闭锁定',
                style: TextStyle(color: Colors.red.shade400)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (choice == null) return;

    // Verify current PIN before making changes
    final currentPin = DataSp.getLockScreenPassword()!;
    bool verified = false;
    await screenLock(
      context: ctx,
      correctString: currentPin,
      canCancel: true,
      onUnlocked: () {
        verified = true;
        Navigator.of(ctx).pop();
      },
      onCancelled: () => Navigator.of(ctx).pop(),
    );
    if (!verified) return;

    if (choice == 'disable') {
      await DataSp.clearLockScreenPassword();
      await DataSp.closeBiometric();
      _refreshLockState();
    } else {
      // change
      await screenLockCreate(
        context: ctx,
        title: const Text('设置新 PIN 码'),
        confirmTitle: const Text('再次确认新 PIN 码'),
        canCancel: true,
        onCancelled: () => Navigator.of(ctx).pop(),
        onConfirmed: (pin) async {
          await DataSp.putLockScreenPassword(pin);
          Navigator.of(ctx).pop();
        },
      );
      _refreshLockState();
    }
  }

  Future<void> toggleBiometric() async {
    if (!lockEnabled.value) return;
    if (biometricEnabled.value) {
      await DataSp.closeBiometric();
    } else {
      await DataSp.openBiometric();
    }
    _refreshLockState();
  }

  void blacklist() => AppNavigator.startBlacklist();

  void languageSetting() => AppNavigator.startLanguageSetup();

  void _updateLanguage() {
    var index = DataSp.getLanguage() ?? 0;
    switch (index) {
      case 1:
        curLanguage.value = StrRes.chinese;
        break;
      case 2:
        curLanguage.value = StrRes.english;
        break;
      default:
        curLanguage.value = StrRes.followSystem;
        break;
    }
  }
}
