import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatReactionBar extends StatelessWidget {
  const ChatReactionBar({
    Key? key,
    required this.reactionMap,
    required this.isISend,
  }) : super(key: key);

  // { emoji → [senderID, ...] }
  final Map<String, List<String>> reactionMap;
  final bool isISend;

  @override
  Widget build(BuildContext context) {
    if (reactionMap.isEmpty) return const SizedBox.shrink();
    final entries = reactionMap.entries.where((e) => e.value.isNotEmpty).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isISend ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: entries.map((e) => _ReactionChip(emoji: e.key, count: e.value.length)).toList(),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.count});
  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 4.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Styles.c_E8EAEF,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 13.sp)),
          if (count > 1) ...[
            2.horizontalSpace,
            Text('$count', style: Styles.ts_8E9AB0_12sp),
          ],
        ],
      ),
    );
  }
}
