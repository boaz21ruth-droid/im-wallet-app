// lib/pages/wallet/swap/intent_order_progress_view.dart
//
// Intent (CoW) orders settle off-chain: the user signed the order (no broadcast),
// and a solver fills it in a batch auction. This view polls /wallet/intent/status
// (挂单中 → 已成交 / 已取消 / 已过期) and offers a CoW Explorer link.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/wallet/swap/intent_service.dart';
import '../../../services/wallet/swap/swap_models.dart';

class IntentOrderProgressView extends StatefulWidget {
  final String orderUid;
  final String chainKey;

  const IntentOrderProgressView({
    super.key,
    required this.orderUid,
    required this.chainKey,
  });

  @override
  State<IntentOrderProgressView> createState() =>
      _IntentOrderProgressViewState();
}

class _IntentOrderProgressViewState extends State<IntentOrderProgressView> {
  final IntentService _intent = IntentService();
  Timer? _timer;
  IntentStatusKind _kind = IntentStatusKind.open;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final s = await _intent.status(
          chainKey: widget.chainKey, orderUid: widget.orderUid);
      if (!mounted) return;
      setState(() => _kind = s.kind);
      if (_kind == IntentStatusKind.fulfilled ||
          _kind == IntentStatusKind.cancelled ||
          _kind == IntentStatusKind.expired) {
        _timer?.cancel();
      }
    } catch (_) {
      // transient; keep polling
    }
  }

  bool get _terminal =>
      _kind == IntentStatusKind.fulfilled ||
      _kind == IntentStatusKind.cancelled ||
      _kind == IntentStatusKind.expired;

  @override
  Widget build(BuildContext context) {
    final done = _kind == IntentStatusKind.fulfilled;
    final failed =
        _kind == IntentStatusKind.cancelled || _kind == IntentStatusKind.expired;
    final explorer = 'https://explorer.cow.fi/orders/${widget.orderUid}';
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_F8F9FA,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('完成',
                style: TextStyle(fontSize: 15.sp, color: Styles.c_0089FF)),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            _icon(done: done, failed: failed),
            SizedBox(height: 20.h),
            Text(
              done
                  ? '兑换完成'
                  : failed
                      ? (_kind == IntentStatusKind.expired ? '订单已过期' : '订单已取消')
                      : '挂单中…',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33),
            ),
            SizedBox(height: 8.h),
            Text(
              done
                  ? '已由 CoW 求解器成交（防夹 · 免 Gas）'
                  : failed
                      ? '可重新发起兑换'
                      : '订单已签名提交，等待求解器成交',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
            ),
            SizedBox(height: 32.h),
            _orderRow(explorer),
            if (!_terminal) ...[
              SizedBox(height: 24.h),
              Text('正在每 5 秒查询订单状态…',
                  style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _icon({required bool done, required bool failed}) {
    if (failed) {
      return Icon(Icons.cancel, size: 64.w, color: Colors.red[400]);
    }
    if (done) {
      return Icon(Icons.check_circle, size: 64.w, color: const Color(0xFF22C55E));
    }
    return SizedBox(
      width: 56.w,
      height: 56.w,
      child: CircularProgressIndicator(
        strokeWidth: 3.w,
        valueColor: AlwaysStoppedAnimation(Styles.c_0089FF),
      ),
    );
  }

  Widget _orderRow(String explorer) {
    final uid = widget.orderUid;
    final short = uid.length > 18
        ? '${uid.substring(0, 10)}…${uid.substring(uid.length - 8)}'
        : uid;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Text('订单',
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: uid));
              EasyLoading.showToast('已复制');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(short,
                    style:
                        TextStyle(fontSize: 13.sp, color: Styles.c_0C1C33)),
                SizedBox(width: 4.w),
                Icon(Icons.copy, size: 13.w, color: Styles.c_8E9AB0),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(explorer),
                mode: LaunchMode.externalApplication),
            child: Icon(Icons.open_in_new, size: 16.w, color: Styles.c_0089FF),
          ),
        ],
      ),
    );
  }
}
