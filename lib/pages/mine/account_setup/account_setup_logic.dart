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

  @override
  void onReady() {
    _updateLanguage();
    super.onReady();
  }

  @override
  void onInit() {
    _queryMyFullInfo();
    refreshTotpStatus();
    super.onInit();
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
