import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:openim_common/openim_common.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/wallet/chain_config.dart';
import '../wallet_logic.dart';

class WalletReceiveView extends StatefulWidget {
  const WalletReceiveView({super.key});

  @override
  State<WalletReceiveView> createState() => _WalletReceiveViewState();
}

class _WalletReceiveViewState extends State<WalletReceiveView> {
  final _qrKey = GlobalKey();

  WalletLogic get logic => Get.find<WalletLogic>();

  Future<void> _saveQrCode(String address, String chainName) async {
    // Request permission (Android 13+ uses photos permission, older uses storage)
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      // Fallback for older Android
      final storage = await Permission.storage.request();
      if (!storage.isGranted) {
        EasyLoading.showToast('需要相册权限才能保存图片');
        return;
      }
    }

    try {
      EasyLoading.show(status: '保存中…');
      final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('图像编码失败');
      final pngBytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        name: 'qr_${chainName}_${address.substring(0, 8)}',
      );
      EasyLoading.dismiss();
      if (result['isSuccess'] == true || result['filePath'] != null) {
        EasyLoading.showToast('二维码已保存到相册');
      } else {
        EasyLoading.showToast('保存失败，请重试');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('保存失败：$e');
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
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  color: Colors.white,
                  child: address.isNotEmpty
                      ? QrImageView(
                          data: address,
                          version: QrVersions.auto,
                          size: 220.w,
                          backgroundColor: Colors.white,
                        )
                      : SizedBox(height: 220.h),
                ),
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
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton.icon(
                  onPressed: address.isNotEmpty
                      ? () => _saveQrCode(address, chainName)
                      : null,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: Text(
                    '保存二维码',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Styles.c_0089FF,
                    side: BorderSide(color: Styles.c_0089FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
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
