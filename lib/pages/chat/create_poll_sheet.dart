import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class CreatePollResult {
  final String question;
  final List<String> options;
  final bool multiVote;

  const CreatePollResult({
    required this.question,
    required this.options,
    required this.multiVote,
  });
}

class CreatePollSheet extends StatefulWidget {
  const CreatePollSheet({super.key});

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _questionCtrl = TextEditingController();
  final _optionCtrls = [TextEditingController(), TextEditingController()];
  bool _multiVote = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= 5) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _submit() {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) {
      IMViews.showToast('请输入投票标题');
      return;
    }
    final options = _optionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (options.length < 2) {
      IMViews.showToast('至少需要 2 个选项');
      return;
    }
    Get.back(result: CreatePollResult(question: question, options: options, multiVote: _multiVote));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 600.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Styles.c_E8EAEF)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: Get.back,
                  child: '取消'.toText..style = Styles.ts_8E9AB0_17sp,
                ),
                const Spacer(),
                '发起投票'.toText..style = Styles.ts_0C1C33_17sp_medium,
                const Spacer(),
                GestureDetector(
                  onTap: _submit,
                  child: '发送'.toText..style = Styles.ts_0089FF_17sp,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  '投票标题'.toText..style = Styles.ts_8E9AB0_14sp,
                  8.verticalSpace,
                  TextField(
                    controller: _questionCtrl,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: '请输入投票标题',
                      filled: true,
                      fillColor: Styles.c_F8F9FA,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                  ),
                  16.verticalSpace,
                  '选项'.toText..style = Styles.ts_8E9AB0_14sp,
                  8.verticalSpace,
                  ...List.generate(
                    _optionCtrls.length,
                    (i) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: TextField(
                        controller: _optionCtrls[i],
                        maxLength: 50,
                        decoration: InputDecoration(
                          hintText: '选项 ${i + 1}',
                          filled: true,
                          fillColor: Styles.c_F8F9FA,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        ),
                      ),
                    ),
                  ),
                  if (_optionCtrls.length < 5)
                    GestureDetector(
                      onTap: _addOption,
                      child: Container(
                        height: 44.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Styles.c_E8EAEF),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: '+ 添加选项'.toText..style = Styles.ts_0089FF_17sp,
                      ),
                    ),
                  16.verticalSpace,
                  Row(
                    children: [
                      '允许多选'.toText..style = Styles.ts_0C1C33_17sp,
                      const Spacer(),
                      StatefulBuilder(
                        builder: (_, setState) => Switch(
                          value: _multiVote,
                          activeThumbColor: Styles.c_0089FF,
                          activeTrackColor: Styles.c_0089FF_opacity50,
                          onChanged: (v) => setState(() => _multiVote = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
