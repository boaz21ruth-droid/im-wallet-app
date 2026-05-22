import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'wallet_create_view.dart';
import 'wallet_import_view.dart';

class WalletOnboardView extends StatelessWidget {
  const WalletOnboardView({super.key});

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
                child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 40.w),
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
                '完全自托管，私钥从不离开您的设备',
                style: TextStyle(fontSize: 15.sp, color: Styles.c_8E9AB0),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _FeatureRow(icon: Icons.security, text: 'AES-256-GCM 加密保护'),
              SizedBox(height: 16.h),
              _FeatureRow(icon: Icons.account_tree, text: '支持 ETH / BSC / Polygon / TRON'),
              SizedBox(height: 16.h),
              _FeatureRow(icon: Icons.fingerprint, text: '生物识别 + 密码双重保护'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const WalletCreateView()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.c_0089FF,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '创建新钱包',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () => Get.to(() => const WalletImportView()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Styles.c_0089FF,
                    side: BorderSide(color: Styles.c_0089FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    '导入已有钱包',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
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
            color: Styles.c_0089FF.withOpacity(0.12),
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
