import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'edit_announcement_logic.dart';

class EditAnnouncementPage extends StatelessWidget {
  final logic = Get.find<EditAnnouncementLogic>();

  EditAnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(
        title: StrRes.editGroupAnnouncement,
        right: StrRes.save.toText
          ..style = Styles.ts_0C1C33_17sp
          ..onTap = logic.save,
      ),
      backgroundColor: Styles.c_FFFFFF,
      body: Column(
        children: [
          22.verticalSpace,
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: Styles.c_E8EAEF,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: TextField(
              controller: logic.inputCtrl,
              style: Styles.ts_0C1C33_17sp,
              autofocus: true,
              maxLines: 5,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: StrRes.noAnnouncement,
                hintStyle: Styles.ts_8E9AB0_14sp,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10.h,
                  horizontal: 12.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
