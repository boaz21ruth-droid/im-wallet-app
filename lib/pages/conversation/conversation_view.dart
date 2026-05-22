import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim/core/controller/im_controller.dart';
import 'package:openim_common/openim_common.dart';
import 'package:sprintf/sprintf.dart';

import 'conversation_logic.dart';

class ConversationPage extends StatelessWidget {
  final logic = Get.find<ConversationLogic>();
  final im = Get.find<IMController>();

  ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: Styles.c_F8F9FA,
          appBar: TitleBar.conversation(
            popCtrl: logic.popCtrl,
            onAddFriend: logic.addFriend,
            onAddGroup: logic.addGroup,
            onCreateGroup: logic.createGroup,
            left: Expanded(
              child: Row(
                children: [
                  AvatarView(
                    width: 36.w,
                    height: 36.h,
                    url: im.userInfo.value.faceURL,
                    text: im.userInfo.value.nickname,
                    textStyle: Styles.ts_FFFFFF_14sp,
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StrRes.home.toText..style = Styles.ts_0C1C33_20sp_semibold,
                        if (null != logic.imSdkStatus && (!logic.reInstall || logic.isFailedSdkStatus))
                          SyncStatusView(
                            isFailed: logic.isFailedSdkStatus,
                            statusStr: logic.imSdkStatus!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              _buildSearchBar(),
              if (logic.list.isNotEmpty) _buildActiveNow(),
              _buildRecentChatsHeader(),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (_, index) => _buildItemView(
                    logic.list.elementAt(index),
                  ),
                  itemCount: logic.list.length,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildSearchBar() => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: SearchBox(
          enabled: false,
          hintText: StrRes.search,
        ),
      );

  Widget _buildActiveNow() {
    final active = logic.list.take(6).toList();
    return Container(
      color: Styles.c_FFFFFF,
      padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 10.h),
            child: StrRes.activeNow.toText..style = Styles.ts_0C1C33_17sp_semibold,
          ),
          SizedBox(
            height: 86.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: active.length,
              separatorBuilder: (_, __) => 16.horizontalSpace,
              itemBuilder: (_, i) {
                final info = active[i];
                return SizedBox(
                  width: 60.w,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          AvatarView(
                            width: 56.w,
                            height: 56.h,
                            url: info.faceURL,
                            text: logic.getShowName(info),
                            isGroup: logic.isGroupChat(info),
                            textStyle: Styles.ts_FFFFFF_14sp,
                          ),
                          Positioned(
                            bottom: 1.h,
                            right: 1.w,
                            child: Container(
                              width: 12.w,
                              height: 12.h,
                              decoration: BoxDecoration(
                                color: Styles.c_18E875,
                                shape: BoxShape.circle,
                                border: Border.all(color: Styles.c_FFFFFF, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      4.verticalSpace,
                      logic.getShowName(info).toText
                        ..style = Styles.ts_8E9AB0_10sp
                        ..maxLines = 1
                        ..overflow = TextOverflow.ellipsis
                        ..textAlign = TextAlign.center,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChatsHeader() => Container(
        color: Styles.c_F8F9FA,
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 8.h),
        child: Row(
          children: [
            StrRes.recentChats.toText..style = Styles.ts_0C1C33_17sp_semibold,
            const Spacer(),
          ],
        ),
      );

  Widget _buildItemView(ConversationInfo info) => Ink(
        color: (info.isPinned ?? false) ? Styles.c_F0F2F6 : Styles.c_FFFFFF,
        child: InkWell(
          onTap: () => logic.toChat(conversationInfo: info),
          onLongPress: () => logic.showConversationMenu(info),
          child: Stack(
            children: [
              Container(
                height: 72.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        AvatarView(
                          width: 48.w,
                          height: 48.h,
                          text: logic.getShowName(info),
                          url: info.faceURL,
                          isGroup: logic.isGroupChat(info),
                          textStyle: Styles.ts_FFFFFF_14sp_medium,
                        ),
                      ],
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 180.w),
                                child: logic.getShowName(info).toText
                                  ..style = Styles.ts_0C1C33_17sp
                                  ..maxLines = 1
                                  ..overflow = TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              logic.getTime(info).toText..style = Styles.ts_8E9AB0_12sp,
                            ],
                          ),
                          3.verticalSpace,
                          Row(
                            children: [
                              Expanded(
                                child: MatchTextView(
                                  text: logic.getContent(info),
                                  textStyle: Styles.ts_8E9AB0_14sp,
                                  prefixSpan: TextSpan(
                                    text: '',
                                    children: [
                                      if (logic.getUnreadCount(info) > 0)
                                        TextSpan(
                                          text: '[${sprintf(StrRes.nPieces, [logic.getUnreadCount(info)])}] ',
                                          style: Styles.ts_8E9AB0_14sp,
                                        ),
                                      TextSpan(
                                        text: logic.getPrefixTag(info),
                                        style: Styles.ts_0089FF_14sp,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              8.horizontalSpace,
                              UnreadCountView(count: logic.getUnreadCount(info)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (info.isPinned ?? false)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Icon(Icons.push_pin, size: 12.r, color: Styles.c_8E9AB0),
                ),
            ],
          ),
        ),
      );
}
