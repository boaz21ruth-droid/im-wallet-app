// lib/pages/wallet/swap/swap_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import 'swap_logic.dart';

class SwapView extends StatelessWidget {
  const SwapView({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<SwapLogic>();
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
          '闪兑',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Styles.c_0C1C33,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: Styles.c_0C1C33, size: 22.w),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChainChip(logic: logic),
            SizedBox(height: 16.h),
            _TokenCard(
              label: '支付',
              tokenSymbol: 'ETH (mock)',
              amount: '1.0',
            ),
            SizedBox(height: 12.h),
            Center(
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Styles.c_FFFFFF,
                  shape: BoxShape.circle,
                  border: Border.all(color: Styles.c_E8EAEF),
                ),
                child: Icon(Icons.swap_vert,
                    color: Styles.c_0089FF, size: 20.w),
              ),
            ),
            SizedBox(height: 12.h),
            _TokenCard(
              label: '获得',
              tokenSymbol: 'USDT (mock)',
              amount: '3232.50',
            ),
            SizedBox(height: 20.h),
            _QuoteInfoRow(label: '报价方', value: '0x'),
            _QuoteInfoRow(label: '汇率', value: '1 ETH ≈ 3,232.50 USDT'),
            _QuoteInfoRow(label: '滑点', value: '0.5%'),
            _QuoteInfoRow(label: '最低获得', value: '3,216.34 USDT'),
            _QuoteInfoRow(label: '平台费', value: '0.3% (9.69 USDT)'),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  disabledBackgroundColor: Styles.c_8E9AB0,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text('Swap (mock)',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChainChip extends StatelessWidget {
  final SwapLogic logic;
  const _ChainChip({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final key = logic.swapChainKey.value;
      final cfg = chains[key];
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Styles.c_E8EAEF),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cfg?.name ?? key,
                style:
                    TextStyle(fontSize: 13.sp, color: Styles.c_0C1C33)),
            SizedBox(width: 4.w),
            Icon(Icons.keyboard_arrow_down,
                size: 16.w, color: Styles.c_8E9AB0),
          ],
        ),
      );
    });
  }
}

class _TokenCard extends StatelessWidget {
  final String label;
  final String tokenSymbol;
  final String amount;

  const _TokenCard({
    required this.label,
    required this.tokenSymbol,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
              const Spacer(),
              Text('余额: 0',
                  style:
                      TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  amount,
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: Styles.c_0C1C33),
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Styles.c_F8F9FA,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Text(tokenSymbol,
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: Styles.c_0C1C33,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 4.w),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16.w, color: Styles.c_8E9AB0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _QuoteInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
          const Spacer(),
          Text(value,
              style: TextStyle(fontSize: 13.sp, color: Styles.c_0C1C33)),
        ],
      ),
    );
  }
}
