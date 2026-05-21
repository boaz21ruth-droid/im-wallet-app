import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class ThemeController extends GetxController {
  final isDark = false.obs;

  @override
  void onInit() {
    isDark.value = DataSp.getIsDark();
    _apply();
    super.onInit();
  }

  void toggle() {
    isDark.value = !isDark.value;
    DataSp.setIsDark(isDark.value);
    _apply();
    Get.forceAppUpdate();
  }

  void _apply() {
    if (isDark.value) {
      Styles.applyDarkTheme();
    } else {
      Styles.applyLightTheme();
    }
    SystemChrome.setSystemUIOverlayStyle(
      isDark.value ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }
}
