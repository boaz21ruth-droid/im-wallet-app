import 'package:flutter/material.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_logic.dart';
import 'gif_picker.dart';
import 'poll_bubble.dart';

class ChatPage extends StatelessWidget {
  final logic = Get.find<ChatLogic>(tag: GetTags.chat);

  ChatPage({super.key});

  Widget _buildItemView(Message message) {
    final isISend = message.sendID == OpenIM.iMManager.userID;
    final reactionMap = logic.reactions[message.clientMsgID] ?? {};
    return Column(
      crossAxisAlignment: isISend ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildChatItemView(message),
        if (reactionMap.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: isISend ? 0 : 58,
              right: isISend ? 16 : 0,
              bottom: 4,
            ),
            child: ChatReactionBar(reactionMap: reactionMap, isISend: isISend),
          ),
      ],
    );
  }

  Widget _buildChatItemView(Message message) => ChatItemView(
        key: logic.itemKey(message),
        message: message,
        textScaleFactor: logic.scaleFactor.value,
        allAtMap: logic.getAtMapping(message),
        timelineStr: logic.getShowTime(message),
        sendStatusSubject: logic.sendStatusSub,
        leftNickname: logic.getNewestNickname(message),
        leftFaceUrl: logic.getNewestFaceURL(message),
        rightNickname: logic.senderName,
        rightFaceUrl: OpenIM.iMManager.userInfo.faceURL,
        showLeftNickname: !logic.isSingleChat,
        showRightNickname: !logic.isSingleChat,
        onFailedToResend: () => logic.failedResend(message),
        onLongPressMessage: logic.onLongPressMessage,
        onClickItemView: () => logic.parseClickEvent(message),
        visibilityChange: (msg, visible) {
          logic.markMessageAsRead(message, visible);
        },
        onLongPressRightAvatar: () {},
        onTapLeftAvatar: () {
          logic.onTapLeftAvatar(message);
        },
        onVisibleTrulyText: (text) {
          logic.copyTextMap[message.clientMsgID] = text;
        },
        customTypeBuilder: _buildCustomTypeItemView,
        patterns: <MatchPattern>[
          MatchPattern(
            type: PatternType.email,
            onTap: logic.clickLinkText,
          ),
          MatchPattern(
            type: PatternType.url,
            onTap: logic.clickLinkText,
          ),
          MatchPattern(
            type: PatternType.mobile,
            onTap: logic.clickLinkText,
          ),
          MatchPattern(
            type: PatternType.tel,
            onTap: logic.clickLinkText,
          ),
        ],
        mediaItemBuilder: (context, message) {
          return _buildMediaItem(context, message);
        },
        onTapUserProfile: handleUserProfileTap,
      );

  void handleUserProfileTap(({String userID, String name, String? faceURL, String? groupID}) userProfile) {
    final userInfo = UserInfo(userID: userProfile.userID, nickname: userProfile.name, faceURL: userProfile.faceURL);
    logic.viewUserInfo(userInfo);
  }

  Widget? _buildMediaItem(BuildContext context, Message message) {
    if (message.contentType != MessageType.picture && message.contentType != MessageType.video) {
      return null;
    }

    return GestureDetector(
      onTap: () async {
        try {
          IMUtils.previewMediaFile(
              context: context,
              message: message,
              onAutoPlay: (index) {
                return !logic.playOnce;
              },
              muted: logic.rtcIsBusy,
              onPageChanged: (index) {
                logic.playOnce = true;
              }).then((value) {
            logic.playOnce = false;
          });
        } catch (e) {
          IMViews.showToast(e.toString());
        }
      },
      child: Hero(
        tag: message.clientMsgID!,
        child: _buildMediaContent(message),
        placeholderBuilder: (BuildContext context, Size heroSize, Widget child) => child,
      ),
    );
  }

  Widget _buildMediaContent(Message message) {
    final isOutgoing = message.sendID == OpenIM.iMManager.userID;

    if (message.isVideoType) {
      return const SizedBox();
    } else {
      return ChatPictureView(
        isISend: isOutgoing,
        message: message,
      );
    }
  }

  CustomTypeInfo? _buildCustomTypeItemView(_, Message message) {
    final data = IMUtils.parseCustomMessage(message);
    if (null != data) {
      final viewType = data['viewType'];
      if (viewType == CustomMessageType.call) {
        final type = data['type'];
        final content = data['content'];
        final view = ChatCallItemView(type: type, content: content);
        return CustomTypeInfo(view);
      } else if (viewType == CustomMessageType.deletedByFriend || viewType == CustomMessageType.blockedByFriend) {
        final view = ChatFriendRelationshipAbnormalHintView(
          name: logic.nickname.value,
          onTap: logic.sendFriendVerification,
          blockedByFriend: viewType == CustomMessageType.blockedByFriend,
          deletedByFriend: viewType == CustomMessageType.deletedByFriend,
        );
        return CustomTypeInfo(view, false, false);
      } else if (viewType == CustomMessageType.removedFromGroup) {
        return CustomTypeInfo(
          StrRes.removedFromGroupHint.toText..style = Styles.ts_8E9AB0_12sp,
          false,
          false,
        );
      } else if (viewType == CustomMessageType.groupDisbanded) {
        return CustomTypeInfo(
          StrRes.groupDisbanded.toText..style = Styles.ts_8E9AB0_12sp,
          false,
          false,
        );
      } else if (viewType == CustomMessageType.gif) {
        final gifData = data['data'] as Map<String, dynamic>? ?? {};
        final url = gifData['gifUrl'] as String? ?? '';
        return CustomTypeInfo(
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImageUtil.networkImage(url: url, width: 180, fit: BoxFit.cover),
          ),
          false,
          true,
        );
      } else if (viewType == CustomMessageType.sticker) {
        final stickerData = data['data'] as Map<String, dynamic>? ?? {};
        final url = stickerData['stickerUrl'] as String? ?? '';
        return CustomTypeInfo(
          ImageUtil.networkImage(url: url, width: 80, height: 80, fit: BoxFit.contain),
          false,
          true,
        );
      } else if (viewType == CustomMessageType.poll) {
        return CustomTypeInfo(
          PollBubble.fromJson(
            rawData: message.customElem!.data!,
            myUserID: OpenIM.iMManager.userID,
            onVote: (idx) => logic.votePoll(message, idx),
          ),
          false,
          true,
        );
      } else if (viewType == CustomMessageType.pollVote) {
        return CustomTypeInfo(const SizedBox.shrink(), false, false);
      } else if (viewType == CustomMessageType.groupFile) {
        final fileData = data['data'] as Map<String, dynamic>? ?? {};
        final name = fileData['name'] as String? ?? '未知文件';
        final size = fileData['size'] as int? ?? 0;
        final url = fileData['url'] as String? ?? '';
        return CustomTypeInfo(
          GestureDetector(
            onTap: () async {
              if (url.isNotEmpty) await launchUrl(Uri.parse(url));
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              constraints: BoxConstraints(maxWidth: 220.w),
              decoration: BoxDecoration(
                color: Styles.c_FFFFFF,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Styles.c_E8EAEF),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📁', style: TextStyle(fontSize: 28.sp)),
                  10.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        name.toText
                          ..style = Styles.ts_0C1C33_14sp
                          ..maxLines = 2
                          ..overflow = TextOverflow.ellipsis,
                        4.verticalSpace,
                        _formatFileSize(size).toText..style = Styles.ts_8E9AB0_12sp,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          false,
          true,
        );
      }
    }
    return null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Widget? get _groupCallHintView => null;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: logic.willPop(),
      child: Obx(() {
        return Scaffold(
            backgroundColor: Styles.c_F0F2F6,
            appBar: logic.searchMode.value ? _searchAppBar(context) : TitleBar.chat(
              title: logic.nickname.value,
              member: logic.memberStr,
              onCloseMultiModel: logic.exit,
              onClickMoreBtn: logic.chatSetup,
              onClickCallBtn: logic.isGroupChat ? null : logic.call,
              onClickSearchBtn: logic.toggleSearchMode,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Obx(() => logic.showAnnouncementBanner.value
                      ? _AnnouncementBanner(
                          text: logic.announcement.value,
                          onDismiss: logic.dismissBanner,
                        )
                      : const SizedBox()),
                  Expanded(
                    child: WaterMarkBgView(
                text: '',
                path: logic.background.value,
                backgroundColor: Styles.c_FFFFFF,
                floatView: _groupCallHintView,
                bottomView: logic.searchMode.value
                    ? const SizedBox()
                    : Obx(() => ChatInputBox(
                  forceCloseToolboxSub: logic.forceCloseToolbox,
                  controller: logic.inputCtrl,
                  focusNode: logic.focusNode,
                  isNotInGroup: logic.isInvalidGroup,
                  directionalText: logic.directionalText(),
                  onCloseDirectional: logic.onClearDirectional,
                  quoteContent: logic.quoteSummary,
                  onClearQuote: logic.clearQuote,
                  editContent: logic.editSummary,
                  onClearEdit: logic.cancelEdit,
                  onSend: (v) => logic.sendTextMsg(),
                  toolbox: ChatToolBox(
                    onTapAlbum: logic.onTapAlbum,
                    onTapCall: logic.isGroupChat ? null : logic.call,
                    onTapGif: () => _showGifPicker(context),
                    onTapSticker: () => _showStickerPanel(context),
                    onTapFile: logic.isGroupChat ? logic.sendGroupFile : null,
                    onTapPoll: logic.isGroupChat ? logic.createPoll : null,
                  ),
                  voiceRecordBar: const SizedBox(),
                )),
                child: logic.searchMode.value
                    ? _buildSearchResultsView()
                    : ChatListView(
                  onTouch: () => logic.closeToolbox(),
                  itemCount: logic.messageList.length,
                  controller: logic.scrollController,
                  onScrollToBottomLoad: logic.onScrollToBottomLoad,
                  onScrollToTop: logic.onScrollToTop,
                  itemBuilder: (_, index) {
                    final message = logic.indexOfMessage(index);
                    return Obx(() => _buildItemView(message));
                  },
                ),
              ),
                  ),
                ],
              ),
            ));
      }),
    );
  }

  PreferredSizeWidget _searchAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: logic.toggleSearchMode,
      ),
      title: TextField(
        controller: logic.searchCtrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: StrRes.searchInChat,
          border: InputBorder.none,
          hintStyle: Styles.ts_8E9AB0_14sp,
        ),
        onChanged: logic.searchInChat,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            logic.searchCtrl.clear();
            logic.searchResults.clear();
            logic.searchQuery.value = '';
          },
        ),
      ],
    );
  }

  // 注意：此方法已在外层 Obx 中调用，直接读取 observable 无需再包一层 Obx
  Widget _buildSearchResultsView() {
    if (logic.searchQuery.value.isEmpty) {
      return Center(child: Text(StrRes.searchInChat, style: Styles.ts_8E9AB0_14sp));
    }
    if (logic.searchResults.isEmpty) {
      return Center(child: Text(StrRes.noSearchResults, style: Styles.ts_8E9AB0_14sp));
    }
      return ListView.separated(
        itemCount: logic.searchResults.length,
        separatorBuilder: (_, __) => Divider(height: 0.5, color: Styles.c_E8EAEF),
        itemBuilder: (_, index) {
          final msg = logic.searchResults[index];
          final preview = _searchResultPreview(msg);
          return ListTile(
            leading: AvatarView(
              width: 40,
              height: 40,
              url: msg.senderFaceUrl,
              text: msg.senderNickname,
            ),
            title: Text(msg.senderNickname ?? '', style: Styles.ts_0C1C33_14sp),
            subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles.ts_8E9AB0_12sp),
            trailing: Text(
              IMUtils.getChatTimeline(msg.sendTime!, 'MM-dd HH:mm'),
              style: Styles.ts_8E9AB0_12sp,
            ),
            onTap: () => logic.scrollToSearchResult(msg),
          );
        },
      );
  }

  String _searchResultPreview(Message msg) {
    if (msg.isTextType) return msg.textElem?.content ?? '';
    if (msg.isQuoteType) return msg.quoteElem?.text ?? '';
    if (msg.isPictureType) return '[图片]';
    if (msg.isVideoType) return '[视频]';
    if (msg.isVoiceType) return '[语音]';
    if (msg.isFileType) return '[文件]';
    return '[消息]';
  }

  void _showGifPicker(BuildContext context) {
    Get.bottomSheet(
      GifPicker(onSend: logic.sendGif),
      isScrollControlled: true,
    );
  }

  void _showStickerPanel(BuildContext context) {
    Get.bottomSheet(
      ChatStickerPanel(onSend: logic.sendSticker),
      isScrollControlled: true,
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({required this.text, required this.onDismiss});
  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBE6),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 18, color: Color(0xFFD48806)),
          8.horizontalSpace,
          Expanded(
            child: Text(
              text.length > 50 ? '${text.substring(0, 50)}...' : text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF614700)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 18, color: Color(0xFF8E9AB0)),
          ),
        ],
      ),
    );
  }
}
