// lib/pages/wallet/swap/swap_bridge_progress_view.dart
//
// Cross-chain swaps are asynchronous: the source-chain tx is broadcast, then the
// destination delivery is tracked by polling /wallet/bridge/status. This view
// shows that progress (桥接中 → 完成 / 失败) and the source + dest explorer links.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/swap/bridge_service.dart';
import '../../../services/wallet/swap/swap_models.dart';

class SwapBridgeProgressView extends StatefulWidget {
  final String sourceTxHash;
  final String fromChain;
  final String toChain;
  final String tool;

  const SwapBridgeProgressView({
    super.key,
    required this.sourceTxHash,
    required this.fromChain,
    required this.toChain,
    required this.tool,
  });

  @override
  State<SwapBridgeProgressView> createState() => _SwapBridgeProgressViewState();
}

class _SwapBridgeProgressViewState extends State<SwapBridgeProgressView> {
  final BridgeService _bridge = BridgeService();
  Timer? _timer;
  BridgeStatusKind _kind = BridgeStatusKind.pending;
  String? _destTxHash;

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
      final s = await _bridge.status(
        txHash: widget.sourceTxHash,
        fromChain: widget.fromChain,
        toChain: widget.toChain,
        tool: widget.tool,
      );
      if (!mounted) return;
      setState(() {
        _kind = s.kind;
        _destTxHash = s.destTxHash;
      });
      if (_kind == BridgeStatusKind.done || _kind == BridgeStatusKind.failed) {
        _timer?.cancel();
      }
    } catch (_) {
      // transient; keep polling
    }
  }

  bool get _terminal =>
      _kind == BridgeStatusKind.done || _kind == BridgeStatusKind.failed;

  @override
  Widget build(BuildContext context) {
    final done = _kind == BridgeStatusKind.done;
    final failed = _kind == BridgeStatusKind.failed;
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
              failed
                  ? '跨链失败'
                  : done
                      ? '跨链完成'
                      : '桥接中…',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33),
            ),
            SizedBox(height: 8.h),
            Text(
              failed
                  ? '请稍后在区块浏览器核对'
                  : done
                      ? '资金已到账目标链'
                      : '已通过 ${widget.tool} 提交，等待目标链到账',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
            ),
            SizedBox(height: 32.h),
            _explorerRow('源链交易', widget.fromChain, widget.sourceTxHash),
            if (_destTxHash != null && _destTxHash!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              _explorerRow('目标链交易', widget.toChain, _destTxHash!),
            ],
            if (!_terminal) ...[
              SizedBox(height: 24.h),
              Text('正在每 5 秒查询状态…',
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

  Widget _explorerRow(String label, String chainKey, String txHash) {
    final cfg = chains[chainKey];
    final url = cfg == null ? null : '${cfg.txExplorerBase}$txHash';
    final short = txHash.length > 18
        ? '${txHash.substring(0, 10)}…${txHash.substring(txHash.length - 8)}'
        : txHash;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: txHash));
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
          if (url != null) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication),
              child: Icon(Icons.open_in_new, size: 16.w, color: Styles.c_0089FF),
            ),
          ],
        ],
      ),
    );
  }
}
