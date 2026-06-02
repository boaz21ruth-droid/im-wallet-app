import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'account_setup_logic.dart';

class AccountSetupPage extends StatelessWidget {
  final logic = Get.find<AccountSetupLogic>();

  AccountSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(
        title: StrRes.accountSetup,
      ),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() => SingleChildScrollView(
            child: Column(
              children: [
                10.verticalSpace,
                _buildItemView(
                  label: StrRes.blacklist,
                  onTap: logic.blacklist,
                  showRightArrow: true,
                ),
                _buildItemView(
                  label: StrRes.languageSetup,
                  value: logic.curLanguage.value,
                  onTap: logic.languageSetting,
                  showRightArrow: true,
                ),
                10.verticalSpace,
                _buildItemView(
                  label: 'Google 验证器',
                  value: logic.totpEnabled.value ? '已开启' : '未开启',
                  onTap: logic.toggleTotp,
                  showRightArrow: true,
                  isTopRadius: true,
                  isBottomRadius: true,
                ),
                10.verticalSpace,
                _buildItemView(
                  label: '应用锁定',
                  value: logic.lockEnabled.value ? '已开启' : '未开启',
                  onTap: logic.setupAppLock,
                  showRightArrow: true,
                  isTopRadius: true,
                ),
                _buildItemView(
                  label: '生物识别解锁',
                  showSwitchButton: true,
                  switchOn: logic.biometricEnabled.value,
                  onChanged: logic.lockEnabled.value
                      ? (_) => logic.toggleBiometric()
                      : null,
                  isBottomRadius: true,
                ),
              ],
            ),
          )),
    );
  }

  Widget _buildItemView({
    required String label,
    TextStyle? textStyle,
    String? value,
    bool switchOn = false,
    bool isTopRadius = false,
    bool isBottomRadius = false,
    bool showRightArrow = false,
    bool showSwitchButton = false,
    ValueChanged<bool>? onChanged,
    Function()? onTap,
  }) =>
      Container(
        margin: EdgeInsets.symmetric(horizontal: 10.w),
        child: Ink(
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(isTopRadius ? 6.r : 0),
              topLeft: Radius.circular(isTopRadius ? 6.r : 0),
              bottomLeft: Radius.circular(isBottomRadius ? 6.r : 0),
              bottomRight: Radius.circular(isBottomRadius ? 6.r : 0),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 46.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  label.toText..style = textStyle ?? Styles.ts_0C1C33_17sp,
                  const Spacer(),
                  if (value != null && value.isNotEmpty) ...[
                    Text(value, style: TextStyle(fontSize: 14.sp, color: Styles.c_8E9AB0)),
                    SizedBox(width: 6.w),
                  ],
                  if (showSwitchButton)
                    CupertinoSwitch(
                      value: switchOn,
                      activeTrackColor: Styles.c_0089FF,
                      onChanged: onChanged,
                    ),
                  if (showRightArrow)
                    ImageRes.rightArrow.toImage
                      ..width = 24.w
                      ..height = 24.h,
                ],
              ),
            ),
          ),
        ),
      );
}
