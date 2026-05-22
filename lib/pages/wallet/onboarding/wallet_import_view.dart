import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'set_password_view.dart';

class WalletImportView extends StatefulWidget {
  const WalletImportView({super.key});

  @override
  State<WalletImportView> createState() => _WalletImportViewState();
}

class _WalletImportViewState extends State<WalletImportView> {
  final _ctrl = TextEditingController();
  String? _error;

  void _validate() {
    final text = _ctrl.text.trim().toLowerCase();
    final words = text.split(RegExp(r'\s+'));
    if (words.length != 12 && words.length != 24) {
      setState(() => _error = '助记词应为 12 或 24 个单词');
      return;
    }
    setState(() => _error = null);
    Get.to(() => SetPasswordView(mnemonic: text, isCreate: false));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_F8F9FA,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Styles.c_0C1C33, size: 18.w),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '导入助记词',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Styles.c_0C1C33,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入您的 12 或 24 个助记词，用空格分隔。',
              style: TextStyle(fontSize: 15.sp, color: Styles.c_8E9AB0),
            ),
            SizedBox(height: 20.h),
            Container(
              decoration: BoxDecoration(
                color: Styles.c_FFFFFF,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: _error != null ? Colors.red : Styles.c_E8EAEF,
                ),
              ),
              padding: EdgeInsets.all(14.w),
              child: TextField(
                controller: _ctrl,
                maxLines: 6,
                onChanged: (_) => setState(() => _error = null),
                style: TextStyle(fontSize: 15.sp, color: Styles.c_0C1C33),
                decoration: InputDecoration(
                  hintText: 'word1 word2 word3 ...',
                  hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(_error!, style: TextStyle(fontSize: 12.sp, color: Colors.red)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _validate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '导入钱包',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
