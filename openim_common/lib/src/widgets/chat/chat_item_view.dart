import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:openim_common/openim_common.dart';
import 'package:rxdart/rxdart.dart';

import 'chat_notice_view.dart';

double maxWidth = 247.w;
double pictureWidth = 120.w;
double videoWidth = 120.w;
double locationWidth = 220.w;

BorderRadius borderRadius(bool isISend) => BorderRadius.only(
      topLeft: Radius.circular(isISend ? 6.r : 0),
      topRight: Radius.circular(isISend ? 0 : 6.r),
      bottomLeft: Radius.circular(6.r),
      bottomRight: Radius.circular(6.r),
    );

class MsgStreamEv<T> {
  final String id;
  final T value;

  MsgStreamEv({required this.id, required this.value});

  @override
  String toString() {
    return 'MsgStreamEv{msgId: $id, value: $value}';
  }
}

class CustomTypeInfo {
  final Widget customView;
  final bool needBubbleBackground;
  final bool needChatItemContainer;

  CustomTypeInfo(
    this.customView, [
    this.needBubbleBackground = true,
    this.needChatItemContainer = true,
  ]);
}

typedef CustomTypeBuilder = CustomTypeInfo? Function(
  BuildContext context,
  Message message,
);
typedef NotificationTypeBuilder = Widget? Function(
  BuildContext context,
  Message message,
);
typedef ItemViewBuilder = Widget? Function(
  BuildContext context,
  Message message,
);
typedef ItemVisibilityChange = void Function(
  Message message,
  bool visible,
);

class ChatItemView extends StatefulWidget {
  const ChatItemView({
    Key? key,
    this.mediaItemBuilder,
    this.itemViewBuilder,
    this.customTypeBuilder,
    this.notificationTypeBuilder,
    this.sendStatusSubject,
    this.visibilityChange,
    this.timelineStr,
    this.leftNickname,
    this.leftFaceUrl,
    this.rightNickname,
    this.rightFaceUrl,
    required this.message,
    this.textScaleFactor = 1.0,
    this.ignorePointer = false,
    this.showLeftNickname = true,
    this.showRightNickname = false,
    this.highlightColor,
    this.allAtMap = const {},
    this.patterns = const [],
    this.onTapLeftAvatar,
    this.onTapRightAvatar,
    this.onLongPressRightAvatar,
    this.onVisibleTrulyText,
    this.onFailedToResend,
    this.onClickItemView,
    this.onLongPressMessage,
    required this.onTapUserProfile,
  }) : super(key: key);
  final ItemViewBuilder? mediaItemBuilder;
  final ItemViewBuilder? itemViewBuilder;
  final CustomTypeBuilder? customTypeBuilder;
  final NotificationTypeBuilder? notificationTypeBuilder;

  final Subject<MsgStreamEv<bool>>? sendStatusSubject;

  final ItemVisibilityChange? visibilityChange;
  final String? timelineStr;
  final String? leftNickname;
  final String? leftFaceUrl;
  final String? rightNickname;
  final String? rightFaceUrl;
  final Message message;

  final double textScaleFactor;
  final bool ignorePointer;
  final bool showLeftNickname;
  final bool showRightNickname;

  final Color? highlightColor;
  final Map<String, String> allAtMap;
  final List<MatchPattern> patterns;
  final Function()? onTapLeftAvatar;
  final Function()? onTapRightAvatar;
  final Function()? onLongPressRightAvatar;
  final Function(String? text)? onVisibleTrulyText;
  final Function()? onClickItemView;
  final ValueChanged<({String userID, String name, String? faceURL, String? groupID})> onTapUserProfile;

  final Function()? onFailedToResend;
  final Function(Message message)? onLongPressMessage;
  @override
  State<ChatItemView> createState() => _ChatItemViewState();
}

class _ChatItemViewState extends State<ChatItemView> {
  Message get _message => widget.message;

  bool get _isISend => _message.sendID == OpenIM.iMManager.userID;

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      child: Container(
        color: widget.highlightColor,
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Center(child: _child),
      ),
      onVisibilityLost: () {
        widget.visibilityChange?.call(widget.message, false);
      },
      onVisibilityGained: () {
        widget.visibilityChange?.call(widget.message, true);
      },
    );
  }

  Widget get _child => widget.itemViewBuilder?.call(context, _message) ?? _buildChildView();

  Widget _buildChildView() {
    Widget? child;
    String? senderNickname;
    String? senderFaceURL;
    bool isBubbleBg = false;
    /* if (_message.isCallType) {
    } else if (_message.isMeetingType) {
    } else if (_message.isDeletedByFriendType) {
    } else if (_message.isBlockedByFriendType) {
    } else if (_message.isEmojiType) {
    } else if (_message.isTagType) {
    }*/
    if (_message.ex == 'revoked') {
      isBubbleBg = true;
      child = Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Text(
          StrRes.revokeMsg,
          style: Styles.ts_8E9AB0_14sp.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (_message.isTextType) {
      isBubbleBg = true;
      final textWidget = ChatText(
        text: _message.textElem!.content!,
        patterns: widget.patterns,
        textScaleFactor: widget.textScaleFactor,
        onVisibleTrulyText: widget.onVisibleTrulyText,
      );
      child = _message.ex == 'edited'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                textWidget,
                Text(StrRes.editedMark, style: Styles.ts_8E9AB0_12sp),
              ],
            )
          : textWidget;
    } else if (_message.isQuoteType) {
      isBubbleBg = true;
      final quoteElem = _message.quoteElem!;
      final originalMsg = quoteElem.quoteMessage;
      final originalSender = originalMsg?.senderNickname ?? '';
      final originalContent = _quotePreviewText(originalMsg);
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _isISend ? Styles.c_0089FF_opacity20 : Styles.c_E8EAEF,
              borderRadius: BorderRadius.circular(4.r),
              border: Border(
                left: BorderSide(
                  color: _isISend ? Styles.c_0089FF : Styles.c_8E9AB0,
                  width: 3.w,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (originalSender.isNotEmpty)
                  Text(originalSender, style: Styles.ts_0089FF_14sp, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(originalContent, style: Styles.ts_8E9AB0_14sp, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          4.verticalSpace,
          ChatText(
            text: quoteElem.text ?? '',
            patterns: widget.patterns,
            textScaleFactor: widget.textScaleFactor,
            onVisibleTrulyText: widget.onVisibleTrulyText,
          ),
          if (_message.ex == 'edited')
            Align(
              alignment: Alignment.centerRight,
              child: Text(StrRes.editedMark, style: Styles.ts_8E9AB0_12sp),
            ),
        ],
      );
    } else if (_message.isPictureType) {
      child = widget.mediaItemBuilder?.call(context, _message) ??
          ChatPictureView(
            isISend: _isISend,
            message: _message,
          );
    } else if (_message.contentType == MessageType.custom) {
      final typeInfo = widget.customTypeBuilder?.call(context, _message);
      if (typeInfo != null) {
        if (!typeInfo.needChatItemContainer) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: typeInfo.customView,
          );
        }
        isBubbleBg = typeInfo.needBubbleBackground;
        child = typeInfo.customView;
      }
    } else if (_message.isNotificationType) {
      if (_message.contentType == MessageType.groupInfoSetAnnouncementNotification) {
        final map = json.decode(_message.notificationElem!.detail!);
        final ntf = GroupNotification.fromJson(map);
        final noticeContent = ntf.group?.notification;
        senderNickname = ntf.opUser?.nickname;
        senderFaceURL = ntf.opUser?.faceURL;
        child = ChatNoticeView(isISend: _isISend, content: noticeContent!);
      } else {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ChatHintTextView(
            message: _message,
            onTapUserProfile: widget.onTapUserProfile,
          ),
        );
      }
    }

    senderNickname ??= widget.leftNickname ?? _message.senderNickname;
    senderFaceURL ??= widget.leftFaceUrl ?? _message.senderFaceUrl;
    return child = ChatItemContainer(
      id: _message.clientMsgID!,
      isISend: _isISend,
      leftNickname: senderNickname,
      leftFaceUrl: senderFaceURL,
      rightNickname: widget.rightNickname ?? OpenIM.iMManager.userInfo.nickname,
      rightFaceUrl: widget.rightFaceUrl ?? OpenIM.iMManager.userInfo.faceURL,
      showLeftNickname: widget.showLeftNickname,
      showRightNickname: widget.showRightNickname,
      timelineStr: widget.timelineStr,
      timeStr: IMUtils.getChatTimeline(_message.sendTime!, 'HH:mm:ss'),
      hasRead: _message.isRead!,
      isSending: _message.isVideoType ? false : _message.status == MessageStatus.sending,
      isSendFailed: _message.status == MessageStatus.failed,
      isBubbleBg: child == null ? true : isBubbleBg,
      ignorePointer: widget.ignorePointer,
      sendStatusStream: widget.sendStatusSubject,
      onFailedToResend: widget.onFailedToResend,
      onLongPressRightAvatar: widget.onLongPressRightAvatar,
      onTapLeftAvatar: widget.onTapLeftAvatar,
      onTapRightAvatar: widget.onTapRightAvatar,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onClickItemView,
        onLongPress: () => widget.onLongPressMessage?.call(_message),
        child: child ?? ChatText(text: StrRes.unsupportedMessage),
      ),
    );
  }

  String _quotePreviewText(Message? msg) {
    if (msg == null) return '';
    if (msg.isTextType) return msg.textElem?.content ?? '';
    if (msg.isQuoteType) return msg.quoteElem?.text ?? '';
    if (msg.isPictureType) return '[${StrRes.picture}]';
    if (msg.isVideoType) return '[${StrRes.video}]';
    if (msg.isVoiceType) return '[${StrRes.voice}]';
    if (msg.isFileType) return '[${StrRes.file}]';
    return '[${StrRes.unsupportedMessage}]';
  }
}
