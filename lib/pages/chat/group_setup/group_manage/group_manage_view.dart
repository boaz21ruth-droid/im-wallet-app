import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'group_manage_logic.dart';

class GroupManagePage extends StatelessWidget {
  final logic = Get.find<GroupManageLogic>();

  GroupManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(title: StrRes.groupManage),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                10.verticalSpace,
                _buildItemView(
                  text: StrRes.transferGroupOwnerRight,
                  onTap: logic.transferGroupOwnerRight,
                  showRightArrow: true,
                  isTopRadius: true,
                  isBottomRadius: true,
                ),
                if (logic.isOwner) ...[
                  20.verticalSpace,
                  Padding(
                    padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
                    child: '管理员'.toText..style = Styles.ts_8E9AB0_14sp,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    decoration: BoxDecoration(
                      color: Styles.c_FFFFFF,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Column(
                      children: [
                        ...logic.adminList.asMap().entries.map((entry) {
                          final member = entry.value;
                          final isLast = entry.key == logic.adminList.length - 1;
                          return _buildMemberRow(
                            member: member,
                            showDivider: !isLast,
                            trailing: GestureDetector(
                              onTap: () => logic.removeAdmin(member),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Styles.c_E8EAEF),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: '撤销'.toText..style = Styles.ts_8E9AB0_14sp,
                              ),
                            ),
                          );
                        }),
                        _buildItemView(
                          text: '添加管理员',
                          onTap: logic.setAdmin,
                          showRightArrow: true,
                          isTopRadius: logic.adminList.isEmpty,
                          isBottomRadius: true,
                        ),
                      ],
                    ),
                  ),
                ],
                20.verticalSpace,
                Padding(
                  padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
                  child: '禁言管理'.toText..style = Styles.ts_8E9AB0_14sp,
                ),
                _buildItemView(
                  text: '禁言成员',
                  onTap: logic.muteUser,
                  showRightArrow: true,
                  isTopRadius: true,
                  isBottomRadius: true,
                ),
                20.verticalSpace,
                Padding(
                  padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
                  child: '成员管理'.toText..style = Styles.ts_8E9AB0_14sp,
                ),
                _buildItemView(
                  text: '移除成员',
                  onTap: logic.kickUser,
                  showRightArrow: true,
                  isTopRadius: true,
                  isBottomRadius: true,
                ),
                40.verticalSpace,
              ],
            ),
          )),
    );
  }

  Widget _buildMemberRow({
    required GroupMembersInfo member,
    bool showDivider = true,
    Widget? trailing,
  }) =>
      Column(
        children: [
          Container(
            height: 64.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                AvatarView(
                  url: member.faceURL,
                  text: member.nickname,
                  width: 44.w,
                  height: 44.h,
                ),
                10.horizontalSpace,
                Expanded(
                  child: (member.nickname ?? '').toText
                    ..style = Styles.ts_0C1C33_17sp
                    ..maxLines = 1
                    ..overflow = TextOverflow.ellipsis,
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          if (showDivider)
            Container(
              height: 1,
              margin: EdgeInsets.only(left: 70.w),
              color: Styles.c_E8EAEF,
            ),
        ],
      );

  Widget _buildItemView({
    required String text,
    TextStyle? textStyle,
    String? value,
    bool isTopRadius = false,
    bool isBottomRadius = false,
    bool showRightArrow = false,
    Function()? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: 46.h,
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(isTopRadius ? 6.r : 0),
              topLeft: Radius.circular(isTopRadius ? 6.r : 0),
              bottomLeft: Radius.circular(isBottomRadius ? 6.r : 0),
              bottomRight: Radius.circular(isBottomRadius ? 6.r : 0),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: text.toText..style = textStyle ?? Styles.ts_0C1C33_17sp),
              if (null != value) value.toText..style = Styles.ts_8E9AB0_14sp,
              if (showRightArrow)
                ImageRes.rightArrow.toImage
                  ..width = 24.w
                  ..height = 24.h,
            ],
          ),
        ),
      );
}
