// lib/pages/wallet/swap/swap_result_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/wallet/chain_config.dart';

class SwapResultView extends StatelessWidget {
  final bool success;
  final String? txHash;
  final String? chainKey;
  final String? errorMessage;

  const SwapResultView({
    super.key,
    required this.success,
    this.txHash,
    this.chainKey,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final explorer = chainKey != null && txHash != null
        ? '${chains[chainKey!]?.txExplorerBase ?? ''}$txHash'
        : null;
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_F8F9FA,
        elevation: 0,
        title: Text(success ? '交易已提交' : '提交失败',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Styles.c_0C1C33)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Styles.c_0C1C33, size: 22.w),
          onPressed: () => Get.until((r) => r.isFirst || r.settings.name == '/'),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: (success ? Colors.green : Colors.red).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check : Icons.close,
                color: success ? Colors.green : Colors.red,
                size: 40.w,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              success ? '已广播至区块链' : (errorMessage ?? '失败'),
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33),
              textAlign: TextAlign.center,
            ),
            if (txHash != null) ...[
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: txHash!));
                  EasyLoading.showToast('已复制');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Styles.c_FFFFFF,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Styles.c_E8EAEF),
                  ),
                  child: Text(
                    _short(txHash!),
                    style: TextStyle(
                        fontSize: 13.sp, color: Styles.c_0C1C33),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (explorer != null && explorer.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse(explorer),
                      mode: LaunchMode.externalApplication),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Styles.c_0089FF,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('查看链上详情',
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w600)),
                ),
              ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () =>
                    Get.until((r) => r.isFirst || r.settings.name == '/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('完成',
                    style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _short(String h) =>
      h.length > 16 ? '${h.substring(0, 10)}…${h.substring(h.length - 8)}' : h;
}
