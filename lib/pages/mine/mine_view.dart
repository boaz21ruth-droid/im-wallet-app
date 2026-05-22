import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/theme_controller.dart';
import '../../routes/app_navigator.dart';
import 'mine_logic.dart';

class MinePage extends StatelessWidget {
  final logic = Get.find<MineLogic>();
  final themeCtrl = Get.find<ThemeController>();

  MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        titleSpacing: 16.w,
        automaticallyImplyLeading: false,
        title: StrRes.settings.toText..style = Styles.ts_0C1C33_20sp_semibold,
        actions: [
          GestureDetector(
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Icon(Icons.search, color: Styles.c_0C1C33, size: 24.r),
            ),
          ),
        ],
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              16.verticalSpace,
              _buildProfileCard(),
              _buildSectionTitle(StrRes.commonSettings),
              _buildSettingsGroup([
                _buildSettingRow(
                  iconBg: const Color(0xFF4A90D9),
                  icon: Icons.notifications_outlined,
                  title: StrRes.notifications,
                  onTap: logic.accountSetup,
                ),
                _buildSettingRow(
                  iconBg: const Color(0xFFFF9500),
                  icon: Icons.lock_outline,
                  title: StrRes.privacySecurity,
                  onTap: logic.accountSetup,
                ),
                _buildSettingRow(
                  iconBg: const Color(0xFF4EDEA3),
                  icon: Icons.palette_outlined,
                  title: StrRes.appearance,
                  trailing: _buildDarkModeTrailing(),
                  onTap: themeCtrl.toggle,
                ),
                _buildSettingRow(
                  iconBg: const Color(0xFF5856D6),
                  icon: Icons.language_outlined,
                  title: StrRes.languageSetup,
                  onTap: AppNavigator.startLanguageSetup,
                ),
              ]),
              _buildSectionTitle(StrRes.storageTraffic),
              _buildSettingsGroup([
                _buildSettingRow(
                  iconBg: const Color(0xFF5856D6),
                  icon: Icons.storage_outlined,
                  title: StrRes.dataStorage,
                  onTap: logic.aboutUs,
                ),
              ]),
              _buildSectionTitle(StrRes.other),
              _buildSettingsGroup([
                _buildSettingRow(
                  iconBg: const Color(0xFF4A90D9),
                  icon: Icons.bookmark_outline,
                  title: StrRes.myFavorites,
                  onTap: logic.viewFavorites,
                ),
                _buildSettingRow(
                  iconBg: const Color(0xFF8E8E93),
                  icon: Icons.info_outline,
                  title: StrRes.aboutUs,
                  onTap: logic.aboutUs,
                ),
              ]),
              20.verticalSpace,
              _buildGradientBanner(),
              20.verticalSpace,
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AvatarView(
                  url: logic.imLogic.userInfo.value.faceURL,
                  text: logic.imLogic.userInfo.value.nickname,
                  width: 64.w,
                  height: 64.h,
                  textStyle: Styles.ts_FFFFFF_14sp,
                ),
                Positioned(
                  bottom: 2.h,
                  right: 2.w,
                  child: Container(
                    width: 14.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Styles.c_18E875,
                      shape: BoxShape.circle,
                      border: Border.all(color: Styles.c_FFFFFF, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (logic.imLogic.userInfo.value.nickname ?? '').toText
                    ..style = Styles.ts_0C1C33_17sp_semibold
                    ..maxLines = 1
                    ..overflow = TextOverflow.ellipsis,
                  4.verticalSpace,
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: logic.copyID,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: (logic.imLogic.userInfo.value.userID ?? '').toText
                            ..style = Styles.ts_8E9AB0_12sp
                            ..maxLines = 1
                            ..overflow = TextOverflow.ellipsis,
                        ),
                        4.horizontalSpace,
                        Icon(Icons.copy_outlined, size: 14.r, color: Styles.c_8E9AB0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: logic.viewMyInfo,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Styles.c_0089FF,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: StrRes.editProfile.toText..style = Styles.ts_FFFFFF_12sp,
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: EdgeInsets.only(left: 16.w, top: 20.h, bottom: 8.h),
        child: title.toText..style = Styles.ts_8E9AB0_13sp,
      );

  Widget _buildSettingsGroup(List<Widget> rows) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(12.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: rows),
      );

  Widget _buildSettingRow({
    required Color iconBg,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Function()? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Styles.c_E8EAEF, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: iconBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: iconBg, size: 20.r),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    title.toText..style = Styles.ts_0C1C33_17sp,
                    if (subtitle != null)
                      subtitle.toText..style = Styles.ts_8E9AB0_12sp,
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: Styles.c_8E9AB0, size: 20.r),
            ],
          ),
        ),
      );

  Widget _buildDarkModeTrailing() => Obx(() => Switch(
        value: themeCtrl.isDark.value,
        onChanged: (_) => themeCtrl.toggle(),
        activeThumbColor: Styles.c_0089FF,
        activeTrackColor: Styles.c_0089FF_opacity50,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ));

  Widget _buildGradientBanner() => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        height: 72.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: const LinearGradient(
            colors: [Color(0xFF005BB3), Color(0xFF4EDEA3)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            16.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StrRes.upgradePro.toText..style = Styles.ts_FFFFFF_17sp_medium,
                  2.verticalSpace,
                  StrRes.upgradeProSubtitle.toText..style = Styles.ts_FFFFFF_12sp,
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: StrRes.learnMore.toText..style = Styles.ts_FFFFFF_12sp,
            ),
          ],
        ),
      );

  Widget _buildLogoutButton() => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        child: GestureDetector(
          onTap: logic.logout,
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Styles.c_FF381F, width: 1.5),
            ),
            child: Center(
              child: StrRes.logout.toText..style = Styles.ts_FF381F_17sp,
            ),
          ),
        ),
      );
}
