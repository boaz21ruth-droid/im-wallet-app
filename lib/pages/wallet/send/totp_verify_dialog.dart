import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../services/totp_service.dart';

/// Shows a modal that gates wallet transfers behind the user's Google
/// Authenticator code. Returns true if the backend accepted the code (the
/// caller should then proceed with signing/broadcasting). Returns false if the
/// user cancelled.
///
/// On invalid / locked / network errors the dialog stays open and displays an
/// error — only an accepted code or an explicit cancel resolves the future.
Future<bool> showTotpVerifyDialog(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Styles.c_FFFFFF,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => const _TotpVerifySheet(),
  );
  return result ?? false;
}

class _TotpVerifySheet extends StatefulWidget {
  const _TotpVerifySheet();

  @override
  State<_TotpVerifySheet> createState() => _TotpVerifySheetState();
}

class _TotpVerifySheetState extends State<_TotpVerifySheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String v) async {
    setState(() => _error = null);
    if (v.length != 6) return;
    setState(() => _submitting = true);
    try {
      final ok = await TotpService.verifyForTransfer(v);
      if (ok) {
        if (mounted) Get.back(result: true);
        return;
      }
      setState(() {
        _submitting = false;
        _error = '验证码无效';
        _ctrl.clear();
      });
    } on TotpException catch (e) {
      setState(() {
        _submitting = false;
        _error = switch (e.kind) {
          TotpError.invalid => '验证码错误，请重试',
          TotpError.locked => '失败次数过多，请稍后再试',
          TotpError.network => '网络异常，请稍后再试',
          _ => e.message,
        };
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Google 验证',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Styles.c_0C1C33,
                  )),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: Styles.c_8E9AB0),
                onPressed: _submitting ? null : () => Get.back(result: false),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text('请输入 Authenticator 中显示的 6 位动态码',
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
          SizedBox(height: 20.h),
          TextField(
            controller: _ctrl,
            autofocus: true,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: TextStyle(fontSize: 22.sp, letterSpacing: 10, color: Styles.c_0C1C33),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(color: Styles.c_8E9AB0, letterSpacing: 10),
              filled: true,
              fillColor: Styles.c_F8F9FA,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 18.h),
            ),
            onChanged: _onChanged,
          ),
          SizedBox(height: 10.h),
          if (_submitting)
            Row(
              children: [
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.w),
                Text('验证中…',
                    style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0)),
              ],
            )
          else if (_error != null)
            Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
