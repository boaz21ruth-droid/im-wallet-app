import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'wallet_logic.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _logic = Get.find<WalletLogic>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _oldObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final old = _oldCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (old.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _error = '请填写所有字段');
      return;
    }
    if (next != confirm) {
      setState(() => _error = '两次输入的新密码不一致');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = '新密码至少 6 位');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    EasyLoading.show(status: '更新中...');
    try {
      final err = await _logic.changePassword(old, next);
      if (!mounted) return;
      if (err != null) {
        setState(() => _error = err);
      } else {
        EasyLoading.showSuccess('密码已更新');
        Get.back();
      }
    } finally {
      EasyLoading.dismiss();
      if (mounted) setState(() => _loading = false);
    }
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
          '修改密码',
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Styles.c_0C1C33),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32.h),
            _buildField(
              label: '原密码',
              ctrl: _oldCtrl,
              obscure: _oldObscure,
              onToggle: () => setState(() => _oldObscure = !_oldObscure),
            ),
            SizedBox(height: 16.h),
            _buildField(
              label: '新密码',
              ctrl: _newCtrl,
              obscure: _newObscure,
              onToggle: () => setState(() => _newObscure = !_newObscure),
            ),
            SizedBox(height: 16.h),
            _buildField(
              label: '确认新密码',
              ctrl: _confirmCtrl,
              obscure: _confirmObscure,
              onToggle: () =>
                  setState(() => _confirmObscure = !_confirmObscure),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(
                _error!,
                style: TextStyle(fontSize: 13.sp, color: Colors.red),
              ),
            ],
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '确认修改',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 13.sp,
              color: Styles.c_8E9AB0,
              fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Styles.c_E8EAEF),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            onSubmitted: onSubmitted,
            style: TextStyle(fontSize: 16.sp, color: Styles.c_0C1C33),
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Styles.c_8E9AB0,
                  size: 20.w,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
