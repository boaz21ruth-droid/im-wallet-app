import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../services/totp_service.dart';

class TotpDisablePage extends StatefulWidget {
  const TotpDisablePage({super.key});

  @override
  State<TotpDisablePage> createState() => _TotpDisablePageState();
}

class _TotpDisablePageState extends State<TotpDisablePage> {
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(String code) async {
    if (code.length != 6 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await TotpService.disable(code);
      if (!mounted) return;
      EasyLoading.showSuccess('已关闭 Google 验证器');
      Get.back(result: true);
    } on TotpException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = switch (e.kind) {
          TotpError.invalid => '验证码错误，请重试',
          TotpError.notEnabled => '尚未绑定',
          _ => '关闭失败：${e.message}',
        };
        _codeCtrl.clear();
        _codeFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: TitleBar.back(title: '关闭 Google 验证器'),
        backgroundColor: Styles.c_F8F9FA,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Styles.c_FFFFFF,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '请输入 Google Authenticator 当前显示的 6 位动态码，输完自动提交。关闭后转账将不再要求二次验证。',
                    style: TextStyle(fontSize: 13.sp, color: Styles.c_0C1C33, height: 1.5),
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: _codeCtrl,
                  focusNode: _codeFocus,
                  keyboardType: TextInputType.number,
                  enabled: !_submitting,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: TextStyle(fontSize: 20.sp, letterSpacing: 8, color: Styles.c_0C1C33),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '------',
                    hintStyle: TextStyle(color: Styles.c_8E9AB0, letterSpacing: 8),
                    filled: true,
                    fillColor: Styles.c_FFFFFF,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    suffixIcon: _submitting
                        ? Padding(
                            padding: EdgeInsets.all(14.w),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    setState(() => _error = null);
                    if (v.length == 6) _submit(v);
                  },
                ),
                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
