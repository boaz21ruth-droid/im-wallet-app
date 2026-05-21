import 'dart:convert';

import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class GroupFileItem {
  final String url;
  final String name;
  final int size;
  final String mimeType;
  final String uploaderID;
  final String uploaderName;
  final int sendTime;

  GroupFileItem({
    required this.url,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.uploaderID,
    required this.uploaderName,
    required this.sendTime,
  });

  factory GroupFileItem.fromMessage(Message msg) {
    final raw = json.decode(msg.customElem?.data ?? '{}');
    final d = raw['data'] as Map<String, dynamic>? ?? {};
    return GroupFileItem(
      url: d['url'] as String? ?? '',
      name: d['name'] as String? ?? '未知文件',
      size: d['size'] as int? ?? 0,
      mimeType: d['mimeType'] as String? ?? '',
      uploaderID: d['uploaderID'] as String? ?? '',
      uploaderName: d['uploaderName'] as String? ?? '',
      sendTime: msg.sendTime ?? 0,
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class GroupFilesLogic extends GetxController {
  late String conversationID;
  final files = <GroupFileItem>[].obs;
  final isLoading = true.obs;
  int _pageIndex = 1;
  static const _pageSize = 40;
  bool _hasMore = true;

  @override
  void onInit() {
    conversationID = Get.arguments['conversationID'] as String;
    super.onInit();
  }

  @override
  void onReady() {
    _load();
    super.onReady();
  }

  Future<void> _load() async {
    if (!_hasMore) return;
    try {
      final result = await OpenIM.iMManager.messageManager.searchLocalMessages(
        conversationID: conversationID,
        messageTypeList: [MessageType.custom],
        pageIndex: _pageIndex,
        count: _pageSize,
      );
      final msgs = result.searchResultItems?.expand((item) => item.messageList ?? <Message>[]).toList() ?? <Message>[];
      final filtered = msgs
          .where((m) {
            try {
              final raw = json.decode(m.customElem?.data ?? '{}');
              return raw['customType'] == CustomMessageType.groupFile;
            } catch (_) {
              return false;
            }
          })
          .map((m) => GroupFileItem.fromMessage(m))
          .toList();
      filtered.sort((a, b) => b.sendTime.compareTo(a.sendTime));
      files.addAll(filtered);
      if (msgs.length < _pageSize) _hasMore = false;
      _pageIndex++;
    } catch (e) {
      IMViews.showToast('加载失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() => _load();

  @override
  void refresh() {
    files.clear();
    _pageIndex = 1;
    _hasMore = true;
    isLoading.value = true;
    _load();
  }
}
