import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../core/controller/theme_controller.dart';
import 'contacts_logic.dart';

class ContactsPage extends StatelessWidget {
  final logic = Get.find<ContactsLogic>();
  final themeCtrl = Get.find<ThemeController>();

  ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        titleSpacing: 16.w,
        automaticallyImplyLeading: false,
        title: StrRes.contacts.toText..style = Styles.ts_0C1C33_20sp_semibold,
        actions: [
          GestureDetector(
            onTap: logic.addContacts,
            child: Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Icon(Icons.person_add_outlined, color: Styles.c_0C1C33, size: 24.r),
            ),
          ),
        ],
      ),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(
        () => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              _buildActionButtons(),
              16.verticalSpace,
              _buildNavItem(
                iconBg: const Color(0xFF4A90D9),
                icon: Icons.person_add,
                label: StrRes.newFriend,
                count: logic.friendApplicationCount,
                onTap: logic.newFriend,
                isFirst: true,
              ),
              _buildNavItem(
                iconBg: const Color(0xFF4EDEA3),
                icon: Icons.group_add,
                label: StrRes.newGroupRequest,
                count: logic.groupApplicationCount,
                onTap: logic.newGroup,
              ),
              _buildNavItem(
                iconBg: const Color(0xFF5856D6),
                icon: Icons.people,
                label: StrRes.myFriend,
                onTap: logic.myFriend,
              ),
              _buildNavItem(
                iconBg: const Color(0xFFFF9500),
                icon: Icons.groups,
                label: StrRes.myGroup,
                onTap: logic.myGroup,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: SearchBox(
          enabled: false,
          hintText: StrRes.search,
        ),
      );

  Widget _buildActionButtons() => Obx(() {
        if (themeCtrl.isDark.value) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _buildDarkActionBtn(
                  icon: Icons.person_add_outlined,
                  iconBg: Styles.c_0089FF,
                  label: StrRes.addFriend,
                  onTap: logic.newFriend,
                ),
                12.horizontalSpace,
                _buildDarkActionBtn(
                  icon: Icons.group_add_outlined,
                  iconBg: Styles.c_18E875,
                  label: StrRes.addGroup,
                  onTap: logic.newGroup,
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: logic.newFriend,
                  child: Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Styles.c_0089FF,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, color: Styles.c_FFFFFF, size: 18.r),
                        6.horizontalSpace,
                        StrRes.addFriend.toText..style = Styles.ts_FFFFFF_14sp_medium,
                      ],
                    ),
                  ),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Styles.c_E8EAEF, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined, color: Styles.c_0C1C33, size: 18.r),
                        6.horizontalSpace,
                        StrRes.inviteFriend.toText..style = Styles.ts_0C1C33_14sp,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      });

  Widget _buildDarkActionBtn({
    required IconData icon,
    required Color iconBg,
    required String label,
    Function()? onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Styles.c_FFFFFF,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: iconBg.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: iconBg, size: 20.r),
                ),
                10.horizontalSpace,
                label.toText..style = Styles.ts_0C1C33_14sp_medium,
              ],
            ),
          ),
        ),
      );

  Widget _buildNavItem({
    required Color iconBg,
    required IconData icon,
    required String label,
    int count = 0,
    bool isFirst = false,
    bool isLast = false,
    Function()? onTap,
  }) =>
      Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        child: Ink(
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isFirst ? 12.r : 0),
              topRight: Radius.circular(isFirst ? 12.r : 0),
              bottomLeft: Radius.circular(isLast ? 12.r : 0),
              bottomRight: Radius.circular(isLast ? 12.r : 0),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isFirst ? 12.r : 0),
              topRight: Radius.circular(isFirst ? 12.r : 0),
              bottomLeft: Radius.circular(isLast ? 12.r : 0),
              bottomRight: Radius.circular(isLast ? 12.r : 0),
            ),
            child: Container(
              height: 60.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Styles.c_E8EAEF, width: 0.5),
                      ),
                    ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: iconBg.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, color: iconBg, size: 22.r),
                  ),
                  14.horizontalSpace,
                  label.toText..style = Styles.ts_0C1C33_17sp,
                  const Spacer(),
                  if (count > 0) UnreadCountView(count: count),
                  4.horizontalSpace,
                  Icon(Icons.chevron_right, color: Styles.c_8E9AB0, size: 20.r),
                ],
              ),
            ),
          ),
        ),
      );
}
