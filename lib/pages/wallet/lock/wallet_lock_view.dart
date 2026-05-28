import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../wallet_logic.dart';

class WalletLockView extends StatefulWidget {
  const WalletLockView({super.key});

  @override
  State<WalletLockView> createState() => _WalletLockViewState();
}

class _WalletLockViewState extends State<WalletLockView> {
  final logic = Get.find<WalletLogic>();
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await logic.vault.isBiometricAvailable();
    setState(() => _biometricAvailable = available && logic.settings.value.biometricEnabled);
    if (_biometricAvailable) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    setState(() { _loading = true; _error = null; });
    try {
      await logic.unlockWithBiometric();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unlockWithPassword() async {
    final pwd = _ctrl.text;
    if (pwd.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    EasyLoading.show(status: '验证中...');
    try {
      final ok = await logic.unlockWithPassword(pwd);
      if (!ok) setState(() => _error = '密码错误');
    } finally {
      EasyLoading.dismiss();
      if (mounted) setState(() => _loading = false);
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 80.h),
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005BB3), Color(0xFF4EDEA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(Icons.lock, color: Colors.white, size: 32.w),
              ),
              SizedBox(height: 24.h),
              Text(
                '解锁钱包',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Styles.c_0C1C33,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '输入密码以访问您的钱包',
                style: TextStyle(fontSize: 15.sp, color: Styles.c_8E9AB0),
              ),
              SizedBox(height: 40.h),
              Container(
                decoration: BoxDecoration(
                  color: Styles.c_FFFFFF,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _error != null ? Colors.red : Styles.c_E8EAEF,
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  obscureText: _obscure,
                  onSubmitted: (_) => _unlockWithPassword(),
                  onChanged: (_) => setState(() => _error = null),
                  style: TextStyle(fontSize: 16.sp, color: Styles.c_0C1C33),
                  decoration: InputDecoration(
                    hintText: '输入密码',
                    hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Styles.c_8E9AB0,
                        size: 20.w,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 8.h),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 13.sp, color: Colors.red),
                ),
              ],
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _loading ? null : _unlockWithPassword,
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
                          '解锁',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_biometricAvailable) ...[
                SizedBox(height: 20.h),
                TextButton.icon(
                  onPressed: _loading ? null : _tryBiometric,
                  icon: const Icon(Icons.fingerprint, size: 24),
                  label: Text(
                    '使用生物识别解锁',
                    style: TextStyle(fontSize: 15.sp),
                  ),
                  style: TextButton.styleFrom(foregroundColor: Styles.c_0089FF),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
