import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../services/totp_service.dart';

/// Bind a Google Authenticator entry to the current user.
///
/// Flow:
///   1. POST /user/totp/setup  → secret + otpauth URL
///   2. Show QR (+ copyable secret) so user can add it in their Authenticator
///   3. User enters first 6-digit code → POST /user/totp/enable
class TotpSetupPage extends StatefulWidget {
  const TotpSetupPage({super.key});

  @override
  State<TotpSetupPage> createState() => _TotpSetupPageState();
}

class _TotpSetupPageState extends State<TotpSetupPage> {
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();
  TotpSetupResult? _setup;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  bool _showClockHint = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _showClockHint = false;
      _codeCtrl.clear();
    });
    try {
      final r = await TotpService.setup();
      setState(() {
        _setup = r;
        _loading = false;
      });
    } on TotpException catch (e) {
      setState(() {
        _loading = false;
        _error = e.kind == TotpError.alreadyEnabled
            ? '已绑定，请先解绑后再重新绑定'
            : '初始化失败：${e.message}';
      });
    }
  }

  Future<void> _submit(String code) async {
    if (code.length != 6 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
      _showClockHint = false;
    });
    try {
      await TotpService.enable(code);
      if (!mounted) return;
      EasyLoading.showSuccess('已开启 Google 验证器');
      Get.back(result: true);
    } on TotpException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        switch (e.kind) {
          case TotpError.invalid:
            _error = '验证码错误，请重试';
            _showClockHint = true;
            _codeCtrl.clear();
            _codeFocus.requestFocus();
            break;
          case TotpError.setupExpired:
            _error = '二维码已过期，请点击下方刷新';
            break;
          case TotpError.alreadyEnabled:
            _error = '已绑定，请先解绑';
            break;
          default:
            _error = '开启失败：${e.message}';
        }
      });
    }
  }

  void _copySecret() {
    final s = _setup?.secret;
    if (s == null || s.isEmpty) return;
    Clipboard.setData(ClipboardData(text: s));
    EasyLoading.showToast('密钥已复制');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: TitleBar.back(title: '绑定 Google 验证器'),
        backgroundColor: Styles.c_F8F9FA,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _setup == null
                  ? _buildErrorState()
                  : _buildSetupForm(),
        ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? '初始化失败',
                  style: TextStyle(fontSize: 14.sp, color: Colors.red)),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: _generate, child: const Text('重试')),
            ],
          ),
        ),
      );

  Widget _buildSetupForm() {
    return SingleChildScrollView(
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
            child: Column(
              children: [
                Text('使用 Google Authenticator 扫描二维码',
                    style: TextStyle(fontSize: 14.sp, color: Styles.c_0C1C33)),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  color: Colors.white,
                  child: QrImageView(
                    data: _setup!.otpauthUrl,
                    size: 200.w,
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                Text('或手动输入密钥',
                    style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0)),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: _copySecret,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Styles.c_F8F9FA,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _setup!.secret,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontFamily: 'monospace',
                              color: Styles.c_0C1C33,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.copy, size: 16.w, color: Styles.c_0089FF),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Text('输入 6 位动态码',
              style: TextStyle(fontSize: 14.sp, color: Styles.c_0C1C33)),
          SizedBox(height: 8.h),
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
              setState(() {
                _error = null;
                _showClockHint = false;
              });
              if (v.length == 6) _submit(v);
            },
          ),
          if (_error != null) ...[
            SizedBox(height: 8.h),
            Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12.sp)),
          ],
          if (_showClockHint) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFFD591)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16.w, color: const Color(0xFFFA8C16)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '若反复错误，请确认运行 Google Authenticator 的手机已开启「自动设置日期与时间」（设置 → 通用 → 日期与时间）。',
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF8C5A1A), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          TextButton.icon(
            onPressed: _submitting ? null : _generate,
            icon: Icon(Icons.refresh, size: 16.w),
            label: Text('刷新二维码', style: TextStyle(fontSize: 13.sp)),
            style: TextButton.styleFrom(foregroundColor: Styles.c_8E9AB0),
          ),
        ],
      ),
    );
  }
}
