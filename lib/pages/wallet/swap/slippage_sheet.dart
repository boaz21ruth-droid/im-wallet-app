// lib/pages/wallet/swap/slippage_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'swap_logic.dart';

/// Reads an Rx value without subscribing the surrounding builder to changes.
/// Used when a snapshot read is intentional (e.g., a one-shot bottom sheet).
extension _RxPeek<T> on Rx<T> {
  T peek() {
    final oldProxy = RxInterface.proxy;
    RxInterface.proxy = null;
    final v = value;
    RxInterface.proxy = oldProxy;
    return v;
  }
}

Future<void> showSlippageSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Styles.c_FFFFFF,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => const _SlippageSheet(),
  );
}

class _SlippageSheet extends StatefulWidget {
  const _SlippageSheet();

  @override
  State<_SlippageSheet> createState() => _SlippageSheetState();
}

class _SlippageSheetState extends State<_SlippageSheet> {
  static const _presets = [10, 50, 100]; // 0.1%, 0.5%, 1.0%
  final logic = Get.find<SwapLogic>();
  final _customCtrl = TextEditingController();

  String _label(int bps) => '${(bps / 100).toStringAsFixed(bps % 100 == 0 ? 1 : 2)}%';

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = logic.slippageBps.peek();
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Styles.c_E8EAEF,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text('滑点设置',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: Styles.c_0C1C33)),
          SizedBox(height: 16.h),
          Row(
            children: _presets.map((bps) {
              final selected = bps == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    logic.setSlippageBps(bps);
                    Get.back();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? Styles.c_0089FF
                          : Styles.c_F8F9FA,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(_label(bps),
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: selected
                                  ? Colors.white
                                  : Styles.c_0C1C33,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12.h),
          Text('自定义',
              style:
                  TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: '例如 0.75',
                    suffixText: '%',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: () {
                  final pct = double.tryParse(_customCtrl.text);
                  if (pct == null || pct <= 0 || pct > 50) return;
                  final bps = (pct * 100).round();
                  if (bps < 1) return; // sub-basis-point inputs round to zero
                  logic.setSlippageBps(bps);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ),
                child: const Text('应用'),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (current >= 300)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text('⚠️ 高滑点会增加被夹击的风险',
                  style: TextStyle(
                      color: Colors.orange[700], fontSize: 12.sp)),
            ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}
