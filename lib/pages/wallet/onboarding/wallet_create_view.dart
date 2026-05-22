import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../wallet_logic.dart';
import 'set_password_view.dart';

class WalletCreateView extends StatefulWidget {
  const WalletCreateView({super.key});

  @override
  State<WalletCreateView> createState() => _WalletCreateViewState();
}

class _WalletCreateViewState extends State<WalletCreateView> {
  final logic = Get.find<WalletLogic>();
  String? _mnemonic;
  bool _revealed = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _generateMnemonic();
  }

  Future<void> _generateMnemonic() async {
    final m = await logic.generateNewMnemonic();
    setState(() => _mnemonic = m);
  }

  List<String> get _words => _mnemonic?.split(' ') ?? [];

  void _proceed() {
    if (!_confirmed) return;
    Get.to(() => SetPasswordView(mnemonic: _mnemonic!, isCreate: true));
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
          '备份助记词',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Styles.c_0C1C33),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningBanner(),
            SizedBox(height: 20.h),
            _buildMnemonicGrid(),
            SizedBox(height: 20.h),
            _buildActions(),
            SizedBox(height: 20.h),
            _buildConfirmCheck(),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _confirmed ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '下一步，设置密码',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFD60A).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '请抄写在纸上并安全保管。助记词丢失将无法恢复钱包，任何人均不应获取您的助记词。',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicGrid() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _words.length,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: Styles.c_0089FF.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Styles.c_8E9AB0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      _revealed ? (_words.length > i ? _words[i] : '') : '••••',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Styles.c_0C1C33,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_revealed)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _revealed = true),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 32),
                      SizedBox(height: 8.h),
                      Text(
                        '点击显示助记词',
                        style: TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _mnemonic == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _mnemonic!));
                    EasyLoading.showToast('已复制');
                  },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Styles.c_0089FF,
              side: BorderSide(color: Styles.c_0089FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _generateMnemonic,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('重新生成'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Styles.c_8E9AB0,
              side: BorderSide(color: Styles.c_8E9AB0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmCheck() {
    return GestureDetector(
      onTap: () => setState(() => _confirmed = !_confirmed),
      child: Row(
        children: [
          Checkbox(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            activeColor: Styles.c_0089FF,
          ),
          Expanded(
            child: Text(
              '我已抄写并安全保存了助记词，清楚地知道丢失助记词将无法恢复资产。',
              style: TextStyle(fontSize: 13.sp, color: Styles.c_0C1C33),
            ),
          ),
        ],
      ),
    );
  }
}
