import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'favorites_logic.dart';

class FavoritesPage extends StatefulWidget {
  final bool asTab;

  const FavoritesPage({super.key, this.asTab = false});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final logic = Get.find<FavoritesLogic>();
  int _selectedTab = 0;
  List<String> get _tabs => [StrRes.favAll, StrRes.favPersonal, StrRes.favGroup, StrRes.favFile];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.asTab
          ? AppBar(
              backgroundColor: Styles.c_FFFFFF,
              elevation: 0,
              title: StrRes.myFavorites.toText..style = Styles.ts_0C1C33_20sp_semibold,
              centerTitle: false,
              automaticallyImplyLeading: false,
            )
          : TitleBar.back(title: StrRes.myFavorites),
      backgroundColor: Styles.c_F8F9FA,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabChips(),
          Expanded(
            child: Obx(() {
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
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
                          12.horizontalSpace,
                          Icon(Icons.star_border, color: Styles.c_8E9AB0, size: 20.r),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChips() => Container(
        color: Styles.c_FFFFFF,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            final i = entry.key;
            final label = entry.value;
            final selected = _selectedTab == i;
            return Padding(
              padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8.w : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: selected ? Styles.c_0089FF : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                    border: selected ? null : Border.all(color: Styles.c_E8EAEF, width: 1.5),
                  ),
                  child: Text(
                    label,
                    style: selected ? Styles.ts_FFFFFF_14sp_medium : Styles.ts_8E9AB0_14sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}
