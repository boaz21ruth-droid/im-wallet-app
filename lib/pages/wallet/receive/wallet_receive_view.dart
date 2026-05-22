import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/wallet/chain_config.dart';
import '../wallet_logic.dart';

class WalletReceiveView extends StatelessWidget {
  const WalletReceiveView({super.key});

  WalletLogic get logic => Get.find<WalletLogic>();

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
          '接收',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Styles.c_0C1C33),
        ),
      ),
      body: Obx(() {
        final address = logic.currentAddress;
        final chainKey = logic.selectedChainKey.value;
        final chainName = chains[chainKey]?.name ?? chainKey.toUpperCase();
        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Text(
                chainName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '仅发送 $chainName 网络资产到此地址',
                style: TextStyle(fontSize: 13.sp, color: Colors.orange),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Styles.c_FFFFFF,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: address.isNotEmpty
                    ? QrImageView(
                        data: address,
                        version: QrVersions.auto,
                        size: 220.w,
                        backgroundColor: Colors.white,
                      )
                    : SizedBox(height: 220.h),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Styles.c_FFFFFF,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Text(
                      '钱包地址',
                      style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Styles.c_0C1C33,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    EasyLoading.showToast('地址已复制');
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(
                    '复制地址',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.c_0089FF,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
