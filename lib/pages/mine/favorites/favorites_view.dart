import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'favorites_logic.dart';

class FavoritesPage extends StatelessWidget {
  final logic = Get.find<FavoritesLogic>();

  FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TitleBar.back(title: StrRes.myFavorites),
      backgroundColor: Styles.c_F8F9FA,
      body: Obx(() {
        if (logic.items.isEmpty) {
          return Center(
            child: Text(StrRes.noAnnouncement, style: Styles.ts_8E9AB0_14sp),
          );
        }
        return ListView.separated(
          itemCount: logic.items.length,
          separatorBuilder: (_, __) => Divider(height: 0.5.h, color: Styles.c_E8EAEF),
          itemBuilder: (_, i) {
            final item = logic.items[i];
            final preview = item['preview'] as String? ?? '';
            final nickname = item['senderNickname'] as String? ?? '';
            final sendTime = item['sendTime'] as int? ?? 0;
            final clientMsgID = item['clientMsgID'] as String? ?? '';
            return Dismissible(
              key: Key(clientMsgID),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.w),
                color: Styles.c_FF381F,
                child: Icon(Icons.delete_outline, color: Styles.c_FFFFFF, size: 24.r),
              ),
              onDismissed: (_) => logic.removeItem(clientMsgID),
              child: Container(
                color: Styles.c_FFFFFF,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nickname, style: Styles.ts_0C1C33_14sp),
                        const Spacer(),
                        Text(
                          IMUtils.getChatTimeline(sendTime, 'MM-dd HH:mm'),
                          style: Styles.ts_8E9AB0_12sp,
                        ),
                      ],
                    ),
                    6.verticalSpace,
                    Text(
                      preview,
                      style: Styles.ts_0C1C33_14sp,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
