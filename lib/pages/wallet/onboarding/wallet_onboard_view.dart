import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/backend_wallet_service.dart';
import 'wallet_create_view.dart';
import 'wallet_import_view.dart';

class WalletOnboardView extends StatefulWidget {
  const WalletOnboardView({super.key});

  @override
  State<WalletOnboardView> createState() => _WalletOnboardViewState();
}

class _WalletOnboardViewState extends State<WalletOnboardView> {
  Map<String, String>? _registeredAddresses;

  bool get _hasRemoteWallet => _registeredAddresses?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _loadRegisteredAddresses();
  }

  Future<void> _loadRegisteredAddresses() async {
    final addresses = await BackendWalletService.getRegisteredAddresses();
    if (!mounted) return;
    setState(() => _registeredAddresses = addresses);
  }

  Future<void> _confirmCreateNewWallet() async {
    if (!_hasRemoteWallet) {
      Get.to(() => const WalletCreateView());
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('创建新的本地钱包？'),
        content: const Text('此账号已在其他设备注册过钱包地址。创建新钱包会生成不同地址，旧钱包资产不会自动同步到当前设备。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('继续创建'),
          ),
        ],
      ),
    );

    if (confirmed == true) Get.to(() => const WalletCreateView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 80.h),
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF005BB3), Color(0xFF4EDEA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 40.w),
              ),
              SizedBox(height: 24.h),
              Text(
                'Web3 Wallet',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Styles.c_0C1C33,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                _hasRemoteWallet ? '检测到此账号已有钱包，请导入助记词恢复' : '完全自托管，私钥从不离开您的设备',
                style: TextStyle(fontSize: 15.sp, color: Styles.c_8E9AB0),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_hasRemoteWallet) ...[
                _RemoteWalletNotice(addresses: _registeredAddresses!),
                SizedBox(height: 20.h),
              ],
              _FeatureRow(icon: Icons.security, text: 'AES-256-GCM 加密保护'),
              SizedBox(height: 16.h),
              _FeatureRow(
                  icon: Icons.account_tree,
                  text: '支持 ETH / BSC / Polygon / TRON'),
              SizedBox(height: 16.h),
              _FeatureRow(icon: Icons.fingerprint, text: '生物识别 + 密码双重保护'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => _hasRemoteWallet
                      ? Get.to(() => const WalletImportView())
                      : _confirmCreateNewWallet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.c_0089FF,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _hasRemoteWallet ? '导入已有钱包' : '创建新钱包',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () => _hasRemoteWallet
                      ? _confirmCreateNewWallet()
                      : Get.to(() => const WalletImportView()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Styles.c_0089FF,
                    side: BorderSide(color: Styles.c_0089FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    _hasRemoteWallet ? '仍要创建新钱包' : '导入已有钱包',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteWalletNotice extends StatelessWidget {
  final Map<String, String> addresses;

  const _RemoteWalletNotice({required this.addresses});

  @override
  Widget build(BuildContext context) {
    final address =
        addresses['eth'] ?? addresses['tron'] ?? addresses.values.first;
    final shortAddress = address.length > 16
        ? '${address.substring(0, 8)}...${address.substring(address.length - 6)}'
        : address;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFC46B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '此账号已有钱包地址',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E)),
                ),
                SizedBox(height: 4.h),
                Text(
                  '请导入原助记词恢复钱包。已记录地址：$shortAddress',
                  style: TextStyle(
                      fontSize: 12.sp, color: const Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Styles.c_0089FF.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: Styles.c_0089FF, size: 20.w),
        ),
        SizedBox(width: 16.w),
        Text(
          text,
          style: TextStyle(fontSize: 15.sp, color: Styles.c_0C1C33),
        ),
      ],
    );
  }
}
