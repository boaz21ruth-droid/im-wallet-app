import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:pull_to_refresh_new/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';
import 'package:openim_live/openim_live.dart';

import '../../core/controller/app_controller.dart';
import '../../core/controller/im_controller.dart';
import '../../core/im_callback.dart';
import '../../routes/app_navigator.dart';
import '../contacts/select_contacts/select_contacts_logic.dart';
import '../conversation/conversation_logic.dart';
import 'group_setup/group_member_list/group_member_list_logic.dart';

class ChatLogic extends SuperController {
  final imLogic = Get.find<IMController>();
  final appLogic = Get.find<AppController>();
  final conversationLogic = Get.find<ConversationLogic>();
  final cacheLogic = Get.find<CacheController>();

  final inputCtrl = TextEditingController();
  final focusNode = FocusNode();
  final scrollController = ScrollController();
  final refreshController = RefreshController();
  bool playOnce = false;

  final forceCloseToolbox = PublishSubject<bool>();
  final sendStatusSub = PublishSubject<MsgStreamEv<bool>>();

  late ConversationInfo conversationInfo;
  Message? searchMessage;
  final nickname = ''.obs;
  final faceUrl = ''.obs;
  Timer? _debounce;
  final messageList = <Message>[].obs;
  final tempMessages = <Message>[];
  final scaleFactor = Config.textScaleFactor.obs;
  final background = "".obs;
  final memberUpdateInfoMap = <String, GroupMembersInfo>{};
  final groupMessageReadMembers = <String, List<String>>{};
  final groupMemberRoleLevel = 1.obs;
  GroupInfo? groupInfo;
  GroupMembersInfo? groupMembersInfo;
  List<GroupMembersInfo> ownerAndAdmin = [];

  final isInGroup = true.obs;
  final memberCount = 0.obs;
  final privateMessageList = <Message>[];
  final isInBlacklist = false.obs;

  final scrollingCacheMessageList = <Message>[];
  final announcement = ''.obs;
  late StreamSubscription conversationSub;
  late StreamSubscription memberAddSub;
  late StreamSubscription memberDelSub;
  late StreamSubscription joinedGroupAddedSub;
  late StreamSubscription joinedGroupDeletedSub;
  late StreamSubscription memberInfoChangedSub;
  late StreamSubscription groupInfoUpdatedSub;
  late StreamSubscription friendInfoChangedSub;
  StreamSubscription? userStatusChangedSub;
  StreamSubscription? selfInfoUpdatedSub;

  late StreamSubscription connectionSub;
  final syncStatus = IMSdkStatus.syncEnded.obs;
  int? lastMinSeq;

  final showCallingMember = false.obs;

  bool _isReceivedMessageWhenSyncing = false;
  bool _isStartSyncing = false;
  bool _isFirstLoad = true;

  final copyTextMap = <String?, String?>{};
  final quoteMsg = Rxn<Message>();
  final editingMsg = Rxn<Message>();
  final showAnnouncementBanner = false.obs;

  // --- 对话内搜索 ---
  final searchMode = false.obs;
  final searchResults = <Message>[].obs;
  final searchQuery = ''.obs;
  final searchCtrl = TextEditingController();

  // --- 消息回应 ---
  // targetMsgID → { emoji → [senderID] }
  final reactions = <String, Map<String, List<String>>>{}.obs;

  String? groupOwnerID;

  final _pageSize = 40;

  RTCBridge? get rtcBridge => PackageBridge.rtcBridge;

  bool get rtcIsBusy => rtcBridge?.hasConnection == true;

  String? get userID => conversationInfo.userID;

  String? get groupID => conversationInfo.groupID;

  bool get isSingleChat => null != userID && userID!.trim().isNotEmpty;

  bool get isGroupChat => null != groupID && groupID!.trim().isNotEmpty;

  String get memberStr => isSingleChat ? "" : "($memberCount)";

  String? get senderName => isSingleChat ? OpenIM.iMManager.userInfo.nickname : groupMembersInfo?.nickname;

  bool get isAdminOrOwner =>
      groupMemberRoleLevel.value == GroupRoleLevel.admin || groupMemberRoleLevel.value == GroupRoleLevel.owner;

  final directionalUsers = <GroupMembersInfo>[].obs;

  bool isCurrentChat(Message message) {
    var senderId = message.sendID;
    var receiverId = message.recvID;
    var groupId = message.groupID;

    var isCurSingleChat = message.isSingleChat &&
        isSingleChat &&
        (senderId == userID || senderId == OpenIM.iMManager.userID && receiverId == userID);
    var isCurGroupChat = message.isGroupChat && isGroupChat && groupID == groupId;
    return isCurSingleChat || isCurGroupChat;
  }

  void scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.jumpTo(0);
    });
  }

  Future<List<Message>> searchMediaMessage() async {
    final messageList = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationInfo.conversationID,
        messageTypeList: [MessageType.picture, MessageType.video],
        count: 500);
    return messageList.searchResultItems?.first.messageList?.reversed.toList() ?? [];
  }

  @override
  void onReady() {
    _resetGroupAtType();
    _clearUnreadCount();

    scrollController.addListener(() {
      focusNode.unfocus();
    });
    super.onReady();
  }

  @override
  void onInit() {
    var arguments = Get.arguments;
    conversationInfo = arguments['conversationInfo'];
    searchMessage = arguments['searchMessage'];
    nickname.value = conversationInfo.showName ?? '';
    faceUrl.value = conversationInfo.faceURL ?? '';
    _initChatConfig();
    _setSdkSyncDataListener();

    conversationSub = imLogic.conversationChangedSubject.listen((value) {
      final obj = value.firstWhereOrNull((e) => e.conversationID == conversationInfo.conversationID);

      if (obj != null) {
        conversationInfo = obj;
      }
    });

    imLogic.onRecvNewMessage = (Message message) async {
      if (isCurrentChat(message)) {
        if (message.contentType == MessageType.typing) {
        } else if (_parseReaction(message)) {
          // reaction 消息只更新 reactions map，不加入消息列表
        } else if (_parseEditEvent(message)) {
          // edit 事件只更新目标消息内容，不加入消息列表
        } else if (message.isRevokeType) {
          _handleRevokeNotification(message);
        } else {
          if (!messageList.contains(message) && !scrollingCacheMessageList.contains(message)) {
            _isReceivedMessageWhenSyncing = true;
            if (scrollController.offset != 0) {
              scrollingCacheMessageList.add(message);
            } else {
              messageList.add(message);
              scrollBottom();
            }
          }
        }
      }
    };

    imLogic.onRecvC2CReadReceipt = (List<ReadReceiptInfo> list) {
      try {
        for (var readInfo in list) {
          if (readInfo.userID == userID) {
            for (var e in messageList) {
              if (readInfo.msgIDList?.contains(e.clientMsgID) == true) {
                e.isRead = true;
                e.hasReadTime = _timestamp;
              }
            }
          }
        }
        messageList.refresh();
      } catch (e) {}
    };

    joinedGroupAddedSub = imLogic.joinedGroupAddedSubject.listen((event) {
      if (event.groupID == groupID) {
        isInGroup.value = true;
        _queryGroupInfo();
      }
    });

    joinedGroupDeletedSub = imLogic.joinedGroupDeletedSubject.listen((event) {
      if (event.groupID == groupID) {
        isInGroup.value = false;
        inputCtrl.clear();
      }
    });

    memberAddSub = imLogic.memberAddedSubject.listen((info) {
      var groupId = info.groupID;
      if (groupId == groupID) {
        _putMemberInfo([info]);
      }
    });

    memberDelSub = imLogic.memberDeletedSubject.listen((info) {
      if (info.groupID == groupID && info.userID == OpenIM.iMManager.userID) {
        isInGroup.value = false;
        inputCtrl.clear();
      }
    });

    memberInfoChangedSub = imLogic.memberInfoChangedSubject.listen((info) {
      if (info.groupID == groupID) {
        if (info.userID == OpenIM.iMManager.userID) {
          groupMemberRoleLevel.value = info.roleLevel ?? GroupRoleLevel.member;
          groupMembersInfo = info;
          ();
        }
        _putMemberInfo([info]);

        final index = ownerAndAdmin.indexWhere((element) => element.userID == info.userID);
        if (info.roleLevel == GroupRoleLevel.member) {
          if (index > -1) {
            ownerAndAdmin.removeAt(index);
          }
        } else if (info.roleLevel == GroupRoleLevel.admin || info.roleLevel == GroupRoleLevel.owner) {
          if (index == -1) {
            ownerAndAdmin.add(info);
          } else {
            ownerAndAdmin[index] = info;
          }
        }

        for (var msg in messageList) {
          if (msg.sendID == info.userID) {
            if (msg.isNotificationType) {
              final map = json.decode(msg.notificationElem!.detail!);
              final ntf = GroupNotification.fromJson(map);
              ntf.opUser?.nickname = info.nickname;
              ntf.opUser?.faceURL = info.faceURL;
              msg.notificationElem?.detail = jsonEncode(ntf);
            } else {
              msg.senderFaceUrl = info.faceURL;
              msg.senderNickname = info.nickname;
            }
          }
        }

        messageList.refresh();
      }
    });

    groupInfoUpdatedSub = imLogic.groupInfoUpdatedSubject.listen((value) {
      if (groupID == value.groupID) {
        groupInfo = value;
        nickname.value = value.groupName ?? '';
        faceUrl.value = value.faceURL ?? '';
        memberCount.value = value.memberCount ?? 0;
        _checkAnnouncement();
      }
    });

    friendInfoChangedSub = imLogic.friendInfoChangedSubject.listen((value) {
      if (userID == value.userID) {
        nickname.value = value.getShowName();
        faceUrl.value = value.faceURL ?? '';

        for (var msg in messageList) {
          if (msg.sendID == value.userID) {
            msg.senderFaceUrl = value.faceURL;
            msg.senderNickname = value.nickname;
          }
        }

        messageList.refresh();
      }
    });

    selfInfoUpdatedSub = imLogic.selfInfoUpdatedSubject.listen((value) {
      for (var msg in messageList) {
        if (msg.sendID == value.userID) {
          msg.senderFaceUrl = value.faceURL;
          msg.senderNickname = value.nickname;
        }
      }

      messageList.refresh();
    });

    inputCtrl.addListener(() {
      sendTypingMsg(focus: true);
      if (_debounce?.isActive ?? false) _debounce?.cancel();

      _debounce = Timer(1.seconds, () {
        sendTypingMsg(focus: false);
      });
    });

    focusNode.addListener(() {
      focusNodeChanged(focusNode.hasFocus);
    });

    imLogic.onSignalingMessage = (value) {
      if (value.userID == userID) {
        messageList.add(value.message);
        scrollBottom();
      }
    };

    super.onInit();
  }

  Future chatSetup() => isSingleChat
      ? AppNavigator.startChatSetup(conversationInfo: conversationInfo)
      : AppNavigator.startGroupChatSetup(conversationInfo: conversationInfo);

  void _putMemberInfo(List<GroupMembersInfo>? list) {
    list?.forEach((member) {
      memberUpdateInfoMap[member.userID!] = member;
    });

    messageList.refresh();
  }

  String? get quoteSummary {
    final msg = quoteMsg.value;
    if (msg == null) return null;
    final sender = msg.senderNickname ?? '';
    String content;
    if (msg.isTextType) {
      content = msg.textElem?.content ?? '';
    } else if (msg.isQuoteType) {
      content = msg.quoteElem?.text ?? '';
    } else if (msg.isPictureType) {
      content = '[${StrRes.picture}]';
    } else if (msg.isVideoType) {
      content = '[${StrRes.video}]';
    } else if (msg.isVoiceType) {
      content = '[${StrRes.voice}]';
    } else if (msg.isFileType) {
      content = '[${StrRes.file}]';
    } else {
      content = '[${StrRes.unsupportedMessage}]';
    }
    return sender.isNotEmpty ? '$sender: $content' : content;
  }

  void setQuote(Message message) {
    quoteMsg.value = message;
    focusNode.requestFocus();
  }

  void clearQuote() => quoteMsg.value = null;

  // --- 消息编辑 ---
  String? get editSummary {
    final msg = editingMsg.value;
    if (msg == null) return null;
    if (msg.isQuoteType) return msg.quoteElem?.text ?? '';
    return msg.textElem?.content ?? '';
  }

  void startEdit(Message message) {
    editingMsg.value = message;
    inputCtrl.text = message.isQuoteType
        ? (message.quoteElem?.text ?? '')
        : (message.textElem?.content ?? '');
    focusNode.requestFocus();
  }

  void cancelEdit() {
    editingMsg.value = null;
    inputCtrl.clear();
  }

  Future<void> _sendEditEvent(String newText) async {
    final target = editingMsg.value!;
    final payload = json.encode({
      'customType': CustomMessageType.editEvent,
      'data': {'targetMsgID': target.clientMsgID, 'newText': newText},
    });
    final msg = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: payload,
      extension: '',
      description: '',
    );
    _applyEdit(target.clientMsgID!, newText);
    cancelEdit();
    await _sendMessage(msg);
  }

  void _applyEdit(String targetMsgID, String newText) {
    final idx = messageList.indexWhere((m) => m.clientMsgID == targetMsgID);
    if (idx < 0) return;
    messageList[idx].textElem?.content = newText;
    messageList[idx].ex = 'edited';
    messageList.refresh();
  }

  bool _parseEditEvent(Message msg) {
    if (msg.contentType != MessageType.custom) return false;
    try {
      final raw = json.decode(msg.customElem?.data ?? '{}');
      if (raw['customType'] != CustomMessageType.editEvent) return false;
      final data = raw['data'] as Map<String, dynamic>;
      _applyEdit(data['targetMsgID'] as String, data['newText'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- 消息撤回 ---
  void _revokeMessage(Message message) async {
    try {
      await OpenIM.iMManager.messageManager.revokeMessage(
        conversationID: conversationInfo.conversationID,
        clientMsgID: message.clientMsgID!,
      );
      message.ex = 'revoked';
      messageList.refresh();
    } catch (e) {
      IMViews.showToast(e.toString());
    }
  }

  void _handleRevokeNotification(Message notification) {
    try {
      final detail = json.decode(notification.notificationElem?.detail ?? '{}');
      final msgID = detail['clientMsgID'] as String?;
      if (msgID != null) {
        final idx = messageList.indexWhere((m) => m.clientMsgID == msgID);
        if (idx >= 0) {
          messageList[idx].ex = 'revoked';
          messageList.refresh();
        }
      }
    } catch (_) {}
  }

  // --- 收藏消息 ---
  void _collectMessage(Message message) {
    String preview;
    if (message.isTextType) {
      preview = message.textElem?.content ?? '';
    } else if (message.isQuoteType) {
      preview = message.quoteElem?.text ?? '';
    } else if (message.isPictureType) {
      preview = '[${StrRes.picture}]';
    } else if (message.isVideoType) {
      preview = '[${StrRes.video}]';
    } else if (message.isVoiceType) {
      preview = '[${StrRes.voice}]';
    } else if (message.isFileType) {
      preview = '[${StrRes.file}]';
    } else {
      preview = '[${StrRes.unsupportedMessage}]';
    }
    DataSp.addFavoriteMessage({
      'clientMsgID': message.clientMsgID,
      'contentType': message.contentType,
      'preview': preview,
      'senderNickname': message.senderNickname,
      'senderFaceUrl': message.senderFaceUrl,
      'sendTime': message.sendTime,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
    IMViews.showToast(StrRes.collectedSuccessfully);
  }

  // --- 群公告 ---
  void _checkAnnouncement() {
    if (!isGroupChat) return;
    final ann = groupInfo?.notification ?? '';
    announcement.value = ann;
    if (ann.isEmpty) {
      showAnnouncementBanner.value = false;
      return;
    }
    final dismissed = DataSp.isAnnouncementDismissed(groupID!);
    showAnnouncementBanner.value = !dismissed;
  }

  void dismissBanner() {
    DataSp.putAnnouncementDismissed(groupID!);
    showAnnouncementBanner.value = false;
  }

  // --- 对话内搜索 ---
  void toggleSearchMode() {
    searchMode.toggle();
    if (!searchMode.value) {
      searchResults.clear();
      searchQuery.value = '';
      searchCtrl.clear();
    }
  }

  void searchInChat(String keyword) async {
    searchQuery.value = keyword;
    if (keyword.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
      conversationID: conversationInfo.conversationID,
      keywordList: [keyword.trim()],
      keywordListMatchType: 0,
      count: 50,
      pageIndex: 1,
    );
    final msgs = result.searchResultItems
            ?.expand<Message>((e) => e.messageList ?? [])
            .toList() ??
        <Message>[];
    searchResults.assignAll(msgs);
  }

  void scrollToSearchResult(Message msg) {
    final index = messageList.indexWhere((m) => m.clientMsgID == msg.clientMsgID);
    if (index >= 0 && scrollController.hasClients) {
      final maxOffset = scrollController.position.maxScrollExtent;
      final offset = maxOffset * (messageList.length - 1 - index) / (messageList.length);
      scrollController.animateTo(
        offset.clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    toggleSearchMode();
  }

  // --- 消息回应 ---
  void _applyReaction(String targetID, String emoji, String senderID) {
    final m = Map<String, List<String>>.from(reactions[targetID] ?? {});
    final users = List<String>.from(m[emoji] ?? []);
    if (!users.contains(senderID)) users.add(senderID);
    m[emoji] = users;
    reactions[targetID] = m;
    reactions.refresh();
  }

  bool _parseReaction(Message msg) {
    if (msg.contentType != MessageType.custom) return false;
    try {
      final raw = json.decode(msg.customElem?.data ?? '{}');
      if (raw['customType'] != CustomMessageType.emoji) return false;
      final data = raw['data'] as Map<String, dynamic>;
      _applyReaction(
        data['targetMsgID'] as String,
        data['emoji'] as String,
        msg.sendID ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void sendReaction(Message targetMsg, String emoji) async {
    final payload = json.encode({
      'customType': CustomMessageType.emoji,
      'data': {'targetMsgID': targetMsg.clientMsgID, 'emoji': emoji},
    });
    final msg = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: payload,
      extension: '',
      description: emoji,
    );
    await _sendMessage(msg);
    _applyReaction(targetMsg.clientMsgID!, emoji, OpenIM.iMManager.userID);
  }

  // --- GIF ---
  void sendGif(String gifUrl, int width, int height) async {
    final payload = json.encode({
      'customType': CustomMessageType.gif,
      'data': {'gifUrl': gifUrl, 'width': width, 'height': height},
    });
    final msg = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: payload,
      extension: '',
      description: '[GIF]',
    );
    _sendMessage(msg);
  }

  // --- 贴纸 ---
  void sendSticker(String stickerUrl, String emoji) async {
    final payload = json.encode({
      'customType': CustomMessageType.sticker,
      'data': {'stickerUrl': stickerUrl, 'emoji': emoji},
    });
    final msg = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: payload,
      extension: '',
      description: '[贴纸]',
    );
    _sendMessage(msg);
  }

  void onLongPressMessage(Message message) {
    if (message.isNotificationType) return;
    if (message.ex == 'revoked') return;
    final isOwnMessage = message.sendID == OpenIM.iMManager.userID;
    final canRevoke = isOwnMessage &&
        (DateTime.now().millisecondsSinceEpoch - (message.sendTime ?? 0)) < 2 * 60 * 1000;
    final canEdit = isOwnMessage && (message.isTextType || message.isQuoteType);
    Get.bottomSheet(
      MessageActionSheet(
        onReply: isInvalidGroup ? null : () => setQuote(message),
        onForward: () => forwardMessage(message),
        onCopy: message.isTextType || message.isQuoteType ? () => _copyMessageText(message) : null,
        onDelete: () => _deleteMessage(message),
        onReact: (emoji) => sendReaction(message, emoji),
        onRevoke: canRevoke ? () => _revokeMessage(message) : null,
        onEdit: canEdit ? () => startEdit(message) : null,
        onCollect: () => _collectMessage(message),
      ),
      backgroundColor: Styles.c_FFFFFF,
    );
  }

  void _copyMessageText(Message message) {
    final text = message.isQuoteType
        ? message.quoteElem?.text ?? ''
        : copyTextMap[message.clientMsgID] ?? message.textElem?.content ?? '';
    Clipboard.setData(ClipboardData(text: text));
    IMViews.showToast(StrRes.copySuccessfully);
  }

  void _deleteMessage(Message message) {
    OpenIM.iMManager.messageManager.deleteMessageFromLocalAndSvr(
      conversationID: conversationInfo.conversationID,
      clientMsgID: message.clientMsgID!,
    );
    messageList.remove(message);
  }

  void forwardMessage(Message message) async {
    final result = await AppNavigator.startSelectContacts(action: SelAction.forward);
    if (result == null) return;
    final checkedList = result['checkedList'] as List? ?? [];
    for (final info in checkedList) {
      final uid = IMUtils.convertCheckedToUserID(info);
      final gid = IMUtils.convertCheckedToGroupID(info);
      await sendForwardMsg(message, userId: uid, groupId: gid);
    }
    if (checkedList.isNotEmpty) IMViews.showToast(StrRes.sendSuccessfully);
  }

  void sendTextMsg() async {
    var content = IMUtils.safeTrim(inputCtrl.text);
    if (content.isEmpty) return;
    if (editingMsg.value != null) {
      await _sendEditEvent(content);
      return;
    }
    Message message;
    if (quoteMsg.value != null) {
      message = await OpenIM.iMManager.messageManager.createQuoteMessage(
        text: content,
        quoteMsg: quoteMsg.value!,
      );
      clearQuote();
    } else {
      message = await OpenIM.iMManager.messageManager.createTextMessage(
        text: content,
      );
    }
    _sendMessage(message);
  }

  Future sendPicture({required String path, bool sendNow = true}) async {
    final file = await IMUtils.compressImageAndGetFile(File(path));

    var message = await OpenIM.iMManager.messageManager.createImageMessageFromFullPath(
      imagePath: file!.path,
    );

    if (sendNow) {
      return _sendMessage(message);
    } else {
      messageList.add(message);
      tempMessages.add(message);
    }
  }

  sendForwardRemarkMsg(
    String content, {
    String? userId,
    String? groupId,
  }) async {
    final message = await OpenIM.iMManager.messageManager.createTextMessage(
      text: content,
    );
    _sendMessage(message, userId: userId, groupId: groupId);
  }

  sendForwardMsg(
    Message originalMessage, {
    String? userId,
    String? groupId,
  }) async {
    var message = await OpenIM.iMManager.messageManager.createForwardMessage(
      message: originalMessage,
    );
    _sendMessage(message, userId: userId, groupId: groupId);
  }

  void sendTypingMsg({bool focus = false}) async {
    if (isSingleChat) {
      OpenIM.iMManager.conversationManager
          .changeInputStates(conversationID: conversationInfo.conversationID, focus: focus);
    }
  }

  void sendCarte({
    required String userID,
    String? nickname,
    String? faceURL,
  }) async {
    var message = await OpenIM.iMManager.messageManager.createCardMessage(
      userID: userID,
      nickname: nickname!,
      faceURL: faceURL,
    );
    _sendMessage(message);
  }

  void sendCustomMsg({
    required String data,
    required String extension,
    required String description,
  }) async {
    var message = await OpenIM.iMManager.messageManager.createCustomMessage(
      data: data,
      extension: extension,
      description: description,
    );
    _sendMessage(message);
  }

  Future _sendMessage(
    Message message, {
    String? userId,
    String? groupId,
    bool addToUI = true,
  }) {
    log('send : ${json.encode(message)}');
    userId = IMUtils.emptyStrToNull(userId);
    groupId = IMUtils.emptyStrToNull(groupId);
    if (null == userId && null == groupId ||
        userId == userID && userId != null ||
        groupId == groupID && groupId != null) {
      if (addToUI) {
        messageList.add(message);
        scrollBottom();
      }
    }
    Logger.print('uid:$userID userId:$userId gid:$groupID groupId:$groupId');
    _reset(message);
    bool useOuterValue = null != userId || null != groupId;

    final recvUserID = useOuterValue ? userId : userID;
    message.recvID = recvUserID;

    return OpenIM.iMManager.messageManager
        .sendMessage(
          message: message,
          userID: recvUserID,
          groupID: useOuterValue ? groupId : groupID,
          offlinePushInfo: Config.offlinePushInfo,
        )
        .then((value) => _sendSucceeded(message, value))
        .catchError((error, _) => _senFailed(message, groupId, userId, error, _))
        .whenComplete(() => _completed());
  }

  void _sendSucceeded(Message oldMsg, Message newMsg) {
    Logger.print('message send success----');
    oldMsg.update(newMsg);
    sendStatusSub.addSafely(MsgStreamEv<bool>(
      id: oldMsg.clientMsgID!,
      value: true,
    ));
  }

  void _senFailed(Message message, String? groupId, String? userId, error, stack) async {
    Logger.print('message send failed userID: $userId groupId:$groupId, catch error :$error  $stack');
    message.status = MessageStatus.failed;
    sendStatusSub.addSafely(MsgStreamEv<bool>(
      id: message.clientMsgID!,
      value: false,
    ));
    if (error is PlatformException) {
      int code = int.tryParse(error.code) ?? 0;
      if (isSingleChat) {
        int? customType;
        if (code == SDKErrorCode.hasBeenBlocked) {
          customType = CustomMessageType.blockedByFriend;
        } else if (code == SDKErrorCode.notFriend) {
          customType = CustomMessageType.deletedByFriend;
        }
        if (null != customType) {
          final hintMessage = (await OpenIM.iMManager.messageManager.createFailedHintMessage(type: customType))
            ..status = 2
            ..isRead = true;
          if (userId != null) {
            if (userId == userID) {
              messageList.add(hintMessage);
            }
          } else {
            messageList.add(hintMessage);
          }
          OpenIM.iMManager.messageManager.insertSingleMessageToLocalStorage(
            message: hintMessage,
            receiverID: userId ?? userID,
            senderID: OpenIM.iMManager.userID,
          );
        }
      } else {
        if ((code == SDKErrorCode.userIsNotInGroup || code == SDKErrorCode.groupDisbanded) && null == groupId) {
          final status = groupInfo?.status;
          final hintMessage = (await OpenIM.iMManager.messageManager.createFailedHintMessage(
              type: status == 2 ? CustomMessageType.groupDisbanded : CustomMessageType.removedFromGroup))
            ..status = 2
            ..isRead = true;
          messageList.add(hintMessage);
          OpenIM.iMManager.messageManager.insertGroupMessageToLocalStorage(
            message: hintMessage,
            groupID: groupID,
            senderID: OpenIM.iMManager.userID,
          );
        }
      }
    }
  }

  void _reset(Message message) {
    if (message.contentType == MessageType.text) {
      inputCtrl.clear();
    }
  }

  void _completed() {
    messageList.refresh();
  }

  void markMessageAsRead(Message message, bool visible) async {
    Logger.print('markMessageAsRead: ${message.textElem?.content}, $visible');
    if (visible && message.contentType! < 1000 && message.contentType! != MessageType.voice) {
      var data = IMUtils.parseCustomMessage(message);
      if (null != data && data['viewType'] == CustomMessageType.call) {
        Logger.print('markMessageAsRead: call message $data');
        return;
      }
      _markMessageAsRead(message);
    }
  }

  _markMessageAsRead(Message message) async {
    if (!message.isRead! && message.sendID != OpenIM.iMManager.userID) {
      try {
        Logger.print('mark conversation message as read：${message.clientMsgID!} ${message.isRead}');
        await OpenIM.iMManager.conversationManager
            .markConversationMessageAsRead(conversationID: conversationInfo.conversationID);
      } catch (e) {
        Logger.print('failed to send group message read receipt： ${message.clientMsgID} ${message.isRead}');
      } finally {
        message.isRead = true;
        message.hasReadTime = _timestamp;
        messageList.refresh();
      }
    }
  }

  _clearUnreadCount() {
    if (conversationInfo.unreadCount > 0) {
      OpenIM.iMManager.conversationManager
          .markConversationMessageAsRead(conversationID: conversationInfo.conversationID);
    }
  }

  void closeToolbox() {
    forceCloseToolbox.addSafely(true);
  }

  void onTapAlbum() async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(Get.context!,
        pickerConfig: AssetPickerConfig(
            sortPathsByModifiedDate: true,
            filterOptions: PMFilter.defaultValue(containsPathModified: true),
            selectPredicate: (_, entity, isSelected) async {
              if (entity.type == AssetType.image) {
                if (await allowSendImageType(entity)) {
                  return true;
                }

                IMViews.showToast(StrRes.supportsTypeHint);

                return false;
              }

              if (entity.videoDuration > const Duration(seconds: 5 * 60)) {
                IMViews.showToast(sprintf(StrRes.selectVideoLimit, [5]) + StrRes.minute);
                return false;
              }
              return true;
            }));
    if (null != assets) {
      for (var asset in assets) {
        await _handleAssets(asset, sendNow: false);
      }

      for (var msg in tempMessages) {
        await _sendMessage(msg, addToUI: false);
      }

      tempMessages.clear();
    }
  }

  Future<bool> allowSendImageType(AssetEntity entity) async {
    final mimeType = await entity.mimeTypeAsync;

    return IMUtils.allowImageType(mimeType);
  }

  Future _handleAssets(AssetEntity? asset, {bool sendNow = true}) async {
    if (null != asset) {
      Logger.print('--------assets type-----${asset.type} create time: ${asset.createDateTime}');
      final originalFile = await asset.file;
      final originalPath = originalFile!.path;
      var path = originalPath.toLowerCase().endsWith('.gif') ? originalPath : originalFile.path;
      Logger.print('--------assets path-----$path');
      switch (asset.type) {
        case AssetType.image:
          await sendPicture(path: path, sendNow: sendNow);
          break;
        default:
          break;
      }
      if (Platform.isIOS) {
        originalFile.deleteSync();
      }
    }
  }

  void onTapDirectionalMessage() async {
    if (null != groupInfo) {
      final list = await AppNavigator.startGroupMemberList(
        groupInfo: groupInfo!,
        opType: GroupMemberOpType.call,
      );
      if (list is List<GroupMembersInfo>) {
        directionalUsers.assignAll(list);
      }
    }
  }

  TextSpan? directionalText() {
    if (directionalUsers.isNotEmpty) {
      final temp = <TextSpan>[];

      for (var e in directionalUsers) {
        final r = TextSpan(
          text: '${e.nickname ?? ''} ${directionalUsers.last == e ? '' : ','} ',
          style: Styles.ts_0089FF_14sp,
        );

        temp.add(r);
      }

      return TextSpan(
        text: '${StrRes.directedTo}:',
        style: Styles.ts_8E9AB0_14sp,
        children: temp,
      );
    }

    return null;
  }

  void onClearDirectional() {
    directionalUsers.clear();
  }

  void parseClickEvent(Message msg) async {
    log('parseClickEvent:${jsonEncode(msg)}');
    if (msg.contentType == MessageType.custom) {
      var data = msg.customElem!.data;
      var map = json.decode(data!);
      var customType = map['customType'];
      if (CustomMessageType.call == customType && !isInBlacklist.value) {}

      return;
    }

    IMUtils.parseClickEvent(
      msg,
      onViewUserInfo: (userInfo) {
        viewUserInfo(userInfo, isCard: msg.isCardType);
      },
    );
  }

  void onTapLeftAvatar(Message message) {
    viewUserInfo(UserInfo()
      ..userID = message.sendID
      ..nickname = message.senderNickname
      ..faceURL = message.senderFaceUrl);
  }

  void onTapRightAvatar() {
    viewUserInfo(OpenIM.iMManager.userInfo);
  }

  void viewUserInfo(UserInfo userInfo, {bool isCard = false}) {
    if (isGroupChat && !isAdminOrOwner && !isCard) {
      if (groupInfo!.lookMemberInfo != 1) {
        AppNavigator.startUserProfilePane(
          userID: userInfo.userID!,
          nickname: userInfo.nickname,
          faceURL: userInfo.faceURL,
          groupID: groupID,
          offAllWhenDelFriend: isSingleChat,
        );
      }
    } else {
      AppNavigator.startUserProfilePane(
        userID: userInfo.userID!,
        nickname: userInfo.nickname,
        faceURL: userInfo.faceURL,
        groupID: groupID,
        offAllWhenDelFriend: isSingleChat,
        forceCanAdd: isCard,
      );
    }
  }

  void clickLinkText(url, type) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  exit() async {
    Get.back();

    return true;
  }

  void focusNodeChanged(bool hasFocus) {
    if (hasFocus) {
      Logger.print('focus:$hasFocus');
      scrollBottom();
    }
  }

  Message indexOfMessage(int index, {bool calculate = true}) => IMUtils.calChatTimeInterval(
        messageList,
        calculate: calculate,
      ).reversed.elementAt(index);

  ValueKey itemKey(Message message) => ValueKey(message.clientMsgID!);

  @override
  void onClose() {
    sendTypingMsg();
    _clearUnreadCount();
    inputCtrl.dispose();
    focusNode.dispose();
    searchCtrl.dispose();
    forceCloseToolbox.close();
    conversationSub.cancel();
    sendStatusSub.close();
    memberAddSub.cancel();
    memberDelSub.cancel();
    memberInfoChangedSub.cancel();
    groupInfoUpdatedSub.cancel();
    friendInfoChangedSub.cancel();
    userStatusChangedSub?.cancel();
    selfInfoUpdatedSub?.cancel();
    joinedGroupAddedSub.cancel();
    joinedGroupDeletedSub.cancel();
    connectionSub.cancel();

    _debounce?.cancel();
    super.onClose();
  }

  String? getShowTime(Message message) {
    if (message.exMap['showTime'] == true) {
      return IMUtils.getChatTimeline(message.sendTime!);
    }
    return null;
  }

  void clearAllMessage() {
    messageList.clear();
  }

  void _initChatConfig() async {
    scaleFactor.value = DataSp.getChatFontSizeFactor();
    var path = DataSp.getChatBackground(otherId) ?? '';
    if (path.isNotEmpty && (await File(path).exists())) {
      background.value = path;
    }
  }

  String get otherId => isSingleChat ? userID! : groupID!;

  void failedResend(Message message) {
    Logger.print('failedResend: ${message.clientMsgID}');
    if (message.status == MessageStatus.sending) {
      return;
    }
    sendStatusSub.addSafely(MsgStreamEv<bool>(
      id: message.clientMsgID!,
      value: true,
    ));

    Logger.print('failedResending: ${message.clientMsgID}');
    _sendMessage(message..status = MessageStatus.sending, addToUI: false);
  }

  static int get _timestamp => DateTime.now().millisecondsSinceEpoch;

  void destroyMsg() {
    for (var message in privateMessageList) {
      OpenIM.iMManager.messageManager.deleteMessageFromLocalAndSvr(
        conversationID: conversationInfo.conversationID,
        clientMsgID: message.clientMsgID!,
      );
    }
  }

  Future _queryMyGroupMemberInfo() async {
    if (!isGroupChat) {
      return;
    }
    var list = await OpenIM.iMManager.groupManager.getGroupMembersInfo(
      groupID: groupID!,
      userIDList: [OpenIM.iMManager.userID],
    );
    groupMembersInfo = list.firstOrNull;
    groupMemberRoleLevel.value = groupMembersInfo?.roleLevel ?? GroupRoleLevel.member;
    if (null != groupMembersInfo) {
      memberUpdateInfoMap[OpenIM.iMManager.userID] = groupMembersInfo!;
    }

    return;
  }

  Future _queryOwnerAndAdmin() async {
    if (isGroupChat) {
      ownerAndAdmin = await OpenIM.iMManager.groupManager.getGroupMemberList(groupID: groupID!, filter: 5, count: 20);
    }
    return;
  }

  void _isJoinedGroup() async {
    if (!isGroupChat) {
      return;
    }
    isInGroup.value = await OpenIM.iMManager.groupManager.isJoinedGroup(
      groupID: groupID!,
    );
    if (!isInGroup.value) {
      return;
    }
    _queryGroupInfo();
    _queryOwnerAndAdmin();
  }

  void _queryGroupInfo() async {
    if (!isGroupChat) {
      return;
    }
    var list = await OpenIM.iMManager.groupManager.getGroupsInfo(
      groupIDList: [groupID!],
    );
    groupInfo = list.firstOrNull;
    groupOwnerID = groupInfo?.ownerUserID;
    if (null != groupInfo?.memberCount) {
      memberCount.value = groupInfo!.memberCount!;
    }
    _queryMyGroupMemberInfo();
    _checkAnnouncement();
  }

  bool get havePermissionMute =>
      isGroupChat &&
      (groupInfo?.ownerUserID == OpenIM.iMManager.userID /*||
          groupMembersInfo?.roleLevel == 2*/
      );

  bool isNotificationType(Message message) => message.contentType! >= 1000;

  Map<String, String> getAtMapping(Message message) {
    return {};
  }

  void _checkInBlacklist() async {
    if (userID != null) {
      var list = await OpenIM.iMManager.friendshipManager.getBlacklist();
      var user = list.firstWhereOrNull((e) => e.userID == userID);
      isInBlacklist.value = user != null;
    }
  }

  bool isExceed24H(Message message) {
    int milliseconds = message.sendTime!;
    return !DateUtil.isToday(milliseconds);
  }

  String? getNewestNickname(Message message) {
    if (isSingleChat) null;

    return message.senderNickname;
  }

  String? getNewestFaceURL(Message message) {
    return message.senderFaceUrl;
  }

  bool get isInvalidGroup => !isInGroup.value && isGroupChat;

  void _resetGroupAtType() {
    if (conversationInfo.groupAtType != GroupAtType.atNormal) {
      OpenIM.iMManager.conversationManager.resetConversationGroupAtType(
        conversationID: conversationInfo.conversationID,
      );
    }
  }

  WillPopCallback? willPop() {
    return null;
  }

  void call() {
    if (rtcIsBusy) {
      IMViews.showToast(StrRes.callingBusy);
      return;
    }

    IMViews.openIMCallSheet(nickname.value, (index) {
      imLogic.call(
        callObj: CallObj.single,
        callType: index == 0 ? CallType.audio : CallType.video,
        inviteeUserIDList: [if (isSingleChat) userID!],
      );
    });
  }

  void onScrollToTop() {
    if (scrollingCacheMessageList.isNotEmpty) {
      messageList.addAll(scrollingCacheMessageList);
      scrollingCacheMessageList.clear();
    }
  }

  String get markText {
    String? phoneNumber = imLogic.userInfo.value.phoneNumber;
    if (phoneNumber != null) {
      int start = phoneNumber.length > 4 ? phoneNumber.length - 4 : 0;
      final sub = phoneNumber.substring(start);
      return "${OpenIM.iMManager.userInfo.nickname!}$sub";
    }
    return OpenIM.iMManager.userInfo.nickname ?? '';
  }

  bool isFailedHintMessage(Message message) {
    if (message.contentType == MessageType.custom) {
      var data = message.customElem!.data;
      var map = json.decode(data!);
      var customType = map['customType'];
      return customType == CustomMessageType.deletedByFriend || customType == CustomMessageType.blockedByFriend;
    }
    return false;
  }

  void sendFriendVerification() => AppNavigator.startSendVerificationApplication(userID: userID);

  void _setSdkSyncDataListener() {
    connectionSub = imLogic.imSdkStatusPublishSubject.listen((value) {
      syncStatus.value = value.status;
      if (value.status == IMSdkStatus.syncStart) {
        _isStartSyncing = true;
      } else if (value.status == IMSdkStatus.syncEnded) {
        if (/*_isReceivedMessageWhenSyncing &&*/ _isStartSyncing) {
          _isReceivedMessageWhenSyncing = false;
          _isStartSyncing = false;
          _isFirstLoad = true;
          _loadHistoryForSyncEnd();
        }
      } else if (value.status == IMSdkStatus.syncFailed) {
        _isReceivedMessageWhenSyncing = false;
        _isStartSyncing = false;
      }
    });
  }

  bool get isSyncFailed => syncStatus.value == IMSdkStatus.syncFailed;

  String? get syncStatusStr {
    switch (syncStatus.value) {
      case IMSdkStatus.syncStart:
      case IMSdkStatus.synchronizing:
        return StrRes.synchronizing;
      case IMSdkStatus.syncFailed:
        return StrRes.syncFailed;
      default:
        return null;
    }
  }

  bool showBubbleBg(Message message) {
    return !isNotificationType(message) && !isFailedHintMessage(message);
  }

  Future<AdvancedMessage> _fetchHistoryMessages() {
    Logger.print(
        '_fetchHistoryMessages: is first load: $_isFirstLoad, last client id: ${_isFirstLoad ? null : messageList.firstOrNull?.clientMsgID}');
    return OpenIM.iMManager.messageManager.getAdvancedHistoryMessageList(
      conversationID: conversationInfo.conversationID,
      count: _pageSize,
      startMsg: _isFirstLoad ? null : messageList.firstOrNull,
    );
  }

  Future<bool> onScrollToBottomLoad() async {
    late List<Message> list;
    final result = await _fetchHistoryMessages();
    if (result.messageList == null || result.messageList!.isEmpty) {
      _getGroupInfoAfterLoadMessage();

      return false;
    }
    list = result.messageList!;
    // 分离 reaction 消息
    final reactionMsgs = list.where(_parseReaction).toList();
    list = list.where((m) => !reactionMsgs.contains(m)).toList();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      // remove the message that has been timed down
      messageList.assignAll(list);
      scrollBottom();

      _getGroupInfoAfterLoadMessage();
    } else {
      messageList.insertAll(0, list);
    }

    return result.isEnd != true;
  }

  Future<void> _loadHistoryForSyncEnd() async {
    final result = await OpenIM.iMManager.messageManager.getAdvancedHistoryMessageList(
      conversationID: conversationInfo.conversationID,
      count: messageList.length < _pageSize ? _pageSize : messageList.length,
      startMsg: null,
    );
    if (result.messageList == null || result.messageList!.isEmpty) return;
    final list = result.messageList!;

    final offset = scrollController.offset;
    messageList.assignAll(list);
    scrollController.jumpTo(offset);
  }

  void _getGroupInfoAfterLoadMessage() {
    if (isGroupChat && ownerAndAdmin.isEmpty) {
      _isJoinedGroup();
    } else {
      _checkInBlacklist();
    }
  }

  recommendFriendCarte(UserInfo userInfo) async {
    final result = await AppNavigator.startSelectContacts(
      action: SelAction.recommend,
      ex: '[${StrRes.carte}]${userInfo.nickname}',
    );
    if (null != result) {
      final customEx = result['customEx'];
      final checkedList = result['checkedList'];
      for (var info in checkedList) {
        final userID = IMUtils.convertCheckedToUserID(info);
        final groupID = IMUtils.convertCheckedToGroupID(info);
        if (customEx is String && customEx.isNotEmpty) {
          _sendMessage(
            await OpenIM.iMManager.messageManager.createTextMessage(
              text: customEx,
            ),
            userId: userID,
            groupId: groupID,
          );
        }
        _sendMessage(
          await OpenIM.iMManager.messageManager.createCardMessage(
            userID: userInfo.userID!,
            nickname: userInfo.nickname!,
            faceURL: userInfo.faceURL,
          ),
          userId: userID,
          groupId: groupID,
        );
      }
    }
  }

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {
    _loadHistoryForSyncEnd();
  }
}
