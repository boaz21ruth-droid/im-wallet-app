import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../wallet_logic.dart';

class SetPasswordView extends StatefulWidget {
  final String mnemonic;
  final bool isCreate;

  const SetPasswordView({super.key, required this.mnemonic, required this.isCreate});

  @override
  State<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<SetPasswordView> {
  final logic = Get.find<WalletLogic>();
  final _pwd1Ctrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final p1 = _pwd1Ctrl.text;
    final p2 = _pwd2Ctrl.text;
    if (p1.length < 8) {
      setState(() => _error = '密码至少 8 位');
      return;
    }
    if (p1 != p2) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    setState(() { _loading = true; _error = null; });
    EasyLoading.show(status: '正在加密...\n(首次设置较慢，约 1-3 秒)');
    try {
      if (widget.isCreate) {
        await logic.createWallet(widget.mnemonic, p1);
      } else {
        await logic.importWallet(widget.mnemonic, p1);
      }
      // Navigate back to root — WalletPage will pick up unlocked state
      Get.until((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = '操作失败: $e');
    } finally {
      EasyLoading.dismiss();
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pwd1Ctrl.dispose();
    _pwd2Ctrl.dispose();
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
          '设置钱包密码',
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
              '密码用于加密您的助记词，请牢记此密码。',
              style: TextStyle(fontSize: 15.sp, color: Styles.c_8E9AB0),
            ),
            SizedBox(height: 28.h),
            _buildField('设置密码（至少 8 位）', _pwd1Ctrl, _obscure1,
                () => setState(() => _obscure1 = !_obscure1)),
            SizedBox(height: 16.h),
            _buildField('确认密码', _pwd2Ctrl, _obscure2,
                () => setState(() => _obscure2 = !_obscure2)),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(_error!, style: TextStyle(fontSize: 13.sp, color: Colors.red)),
            ],
            const Spacer(),
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
                child: Text(
                  widget.isCreate ? '创建钱包' : '导入钱包',
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

  Widget _buildField(String hint, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        onChanged: (_) => setState(() => _error = null),
        style: TextStyle(fontSize: 16.sp, color: Styles.c_0C1C33),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Styles.c_8E9AB0,
              size: 20.w,
            ),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
