import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import 'group_files_logic.dart';

class GroupFilesPage extends StatelessWidget {
  final logic = Get.find<GroupFilesLogic>();

  GroupFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(title: '群文件'),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (logic.files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📁', style: TextStyle(fontSize: 48.sp)),
                16.verticalSpace,
                '暂无文件'.toText..style = Styles.ts_8E9AB0_14sp,
                8.verticalSpace,
                '在聊天中发送文件后将在此显示'.toText..style = Styles.ts_8E9AB0_12sp,
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: logic.files.length,
          separatorBuilder: (_, __) => Container(
            height: 1,
            margin: EdgeInsets.only(left: 72.w),
            color: Styles.c_E8EAEF,
          ),
          itemBuilder: (_, index) => _buildFileItem(logic.files[index]),
        );
      }),
    );
  }

  Widget _buildFileItem(GroupFileItem file) => GestureDetector(
        onTap: () async {
          if (file.url.isNotEmpty) await launchUrl(Uri.parse(file.url));
        },
        child: Container(
          height: 72.h,
          color: Styles.c_FFFFFF,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Styles.c_F0F2F6,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text('📁', style: TextStyle(fontSize: 22.sp)),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    file.name.toText
                      ..style = Styles.ts_0C1C33_14sp
                      ..maxLines = 1
                      ..overflow = TextOverflow.ellipsis,
                    4.verticalSpace,
                    Row(
                      children: [
                        file.formattedSize.toText..style = Styles.ts_8E9AB0_12sp,
                        4.horizontalSpace,
                        '·'.toText..style = Styles.ts_8E9AB0_12sp,
                        4.horizontalSpace,
                        file.uploaderName.toText..style = Styles.ts_8E9AB0_12sp,
                      ],
                    ),
                  ],
                ),
              ),
              ImageRes.rightArrow.toImage
                ..width = 20.w
                ..height = 20.h,
            ],
          ),
        ),
      );
}
