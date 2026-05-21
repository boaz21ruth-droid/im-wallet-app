import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class PollBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final String myUserID;
  final void Function(int optionIndex) onVote;

  const PollBubble({
    super.key,
    required this.data,
    required this.myUserID,
    required this.onVote,
  });

  factory PollBubble.fromJson({
    required String rawData,
    required String myUserID,
    required void Function(int) onVote,
  }) {
    final parsed = json.decode(rawData) as Map<String, dynamic>;
    return PollBubble(
      data: parsed['data'] as Map<String, dynamic>? ?? {},
      myUserID: myUserID,
      onVote: onVote,
    );
  }

  List<Map<String, dynamic>> get _options =>
      (data['options'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  String get _question => data['question'] as String? ?? '';

  bool _hasVoted(Map<String, dynamic> option) =>
      (option['voterIDs'] as List? ?? []).contains(myUserID);

  bool get _iHaveVoted => _options.any(_hasVoted);

  int get _totalVotes =>
      _options.fold(0, (sum, o) => sum + ((o['voterIDs'] as List?)?.length ?? 0));

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final iHaveVoted = _iHaveVoted;
    final totalVotes = _totalVotes;

    return Container(
      constraints: BoxConstraints(maxWidth: 240.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 14.sp)),
              6.horizontalSpace,
              Expanded(
                child: _question.toText
                  ..style = Styles.ts_0C1C33_14sp_medium
                  ..maxLines = 3
                  ..overflow = TextOverflow.ellipsis,
              ),
            ],
          ),
          12.verticalSpace,
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final votes = (opt['voterIDs'] as List?)?.length ?? 0;
            final ratio = totalVotes > 0 ? votes / totalVotes : 0.0;
            final myVote = _hasVoted(opt);

            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GestureDetector(
                onTap: iHaveVoted ? null : () => onVote(idx),
                child: Container(
                  height: 40.h,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: myVote ? Styles.c_0089FF : Styles.c_E8EAEF,
                      width: myVote ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (iHaveVoted)
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            color: myVote
                                ? Styles.c_0089FF.withOpacity(0.15)
                                : Styles.c_E8EAEF.withOpacity(0.5),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: (opt['text'] as String? ?? '').toText
                                ..style = myVote ? Styles.ts_0089FF_14sp : Styles.ts_0C1C33_14sp
                                ..maxLines = 1
                                ..overflow = TextOverflow.ellipsis,
                            ),
                            if (iHaveVoted)
                              '$votes票'.toText..style = Styles.ts_8E9AB0_12sp,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          4.verticalSpace,
          '$totalVotes 人参与'.toText..style = Styles.ts_8E9AB0_12sp,
        ],
      ),
    );
  }
}
