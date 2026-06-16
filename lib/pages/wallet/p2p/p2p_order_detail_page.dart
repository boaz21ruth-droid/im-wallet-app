import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../wallet_logic.dart';
import 'p2p_logic.dart';
import 'p2p_models.dart';

class P2POrderDetailPage extends StatelessWidget {
  final P2POrder order;
  const P2POrderDetailPage({super.key, required this.order});

  P2PLogic get _logic => Get.find<P2PLogic>();
  String get _myAddress => Get.find<WalletLogic>().currentAddress.toLowerCase();

  bool get _isSeller => order.seller.toLowerCase() == _myAddress;
  bool get _isBuyer  => order.buyer.toLowerCase()  == _myAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_F8F9FA,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18.w, color: Styles.c_0C1C33),
          onPressed: Get.back,
        ),
        title: Text('订单详情',
            style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Styles.c_0C1C33)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            SizedBox(height: 16.h),
            _buildInfoCard(),
            SizedBox(height: 16.h),
            _buildAddressCard(),
            SizedBox(height: 24.h),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final (color, icon, text) = _statusInfo();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.$1,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color)),
                SizedBox(height: 4.h),
                Text(text.$2,
                    style: TextStyle(fontSize: 12.sp, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, (String, String)) _statusInfo() {
    switch (order.status) {
      case P2POrder.open:
        return (
          const Color(0xFF10B981),
          Icons.schedule,
          ('待接单', '等待买家接单，挂单中')
        );
      case P2POrder.locked:
        if (_isBuyer) return (
          const Color(0xFFFF9F40),
          Icons.payment,
          ('请完成付款', '请向卖家转账 ¥${order.fiatDisplay.toStringAsFixed(2)}，完成后点击"已付款"')
        );
        return (
          const Color(0xFFFF9F40),
          Icons.hourglass_top,
          ('等待买家付款', '买家正在付款中，请耐心等待')
        );
      case P2POrder.paid:
        if (_isSeller) return (
          const Color(0xFF0089FF),
          Icons.check_circle_outline,
          ('请确认收款', '买家已标记付款，确认收到款项后点击"确认放币"')
        );
        return (
          const Color(0xFF0089FF),
          Icons.hourglass_top,
          ('等待卖家确认', '已标记付款，等待卖家确认收款')
        );
      case P2POrder.released:
        return (const Color(0xFF10B981), Icons.done_all, ('交易完成', '代币已成功释放'));
      case P2POrder.cancelled:
        return (Styles.c_8E9AB0, Icons.cancel_outlined, ('已取消', '订单已取消'));
      case P2POrder.disputed:
        return (const Color(0xFFEF4444), Icons.gavel, ('申诉中', '等待平台仲裁，请保持沟通'));
      default:
        return (Styles.c_8E9AB0, Icons.info_outline, (order.statusLabel, ''));
    }
  }

  Widget _buildInfoCard() {
    return _Card(
      child: Column(
        children: [
          _InfoRow(label: '交易金额', value: '¥${order.fiatDisplay.toStringAsFixed(2)} ${order.fiatCurrency}', valueBold: true),
          _InfoRow(label: 'USDT 数量', value: '${order.tokenDisplay.toStringAsFixed(6)} USDT'),
          _InfoRow(label: '单价', value: '¥${order.unitPrice.toStringAsFixed(4)}/USDT'),
          _InfoRow(label: '付款方式', value: order.payMethod),
          _InfoRow(label: '订单编号', value: '#${order.orderId}', isLast: true),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return _Card(
      child: Column(
        children: [
          _InfoRow(label: '卖家地址', value: _shortAddr(order.seller)),
          if (order.buyer.isNotEmpty)
            _InfoRow(label: '买家地址', value: _shortAddr(order.buyer)),
          _InfoRow(
              label: '交易哈希',
              value: '${order.txHash.substring(0, 10)}...',
              isLast: true),
        ],
      ),
    );
  }

  String _shortAddr(String addr) => addr.length > 16
      ? '${addr.substring(0, 8)}...${addr.substring(addr.length - 6)}'
      : addr;

  Widget _buildActions(BuildContext context) {
    final btns = <Widget>[];

    // Buyer: take open order
    if (order.status == P2POrder.open && !_isSeller) {
      btns.add(_PrimaryButton(
        label: '立即购买',
        color: Styles.c_0089FF,
        onTap: () async {
          final ok = await _logic.doTakeOrder(order);
          if (ok) Get.back();
        },
      ));
    }

    // Buyer: mark paid
    if (order.status == P2POrder.locked && _isBuyer) {
      btns.add(_PrimaryButton(
        label: '已完成付款',
        color: const Color(0xFF10B981),
        onTap: () async {
          final ok = await _logic.doMarkPaid(order);
          if (ok) Get.back();
        },
      ));
    }

    // Seller: confirm release
    if (order.status == P2POrder.paid && _isSeller) {
      btns.add(_PrimaryButton(
        label: '确认放币',
        color: const Color(0xFF10B981),
        onTap: () async {
          final confirmed = await _showConfirmDialog(
              context, '确认放币？', '确认已收到买家的 ¥${order.fiatDisplay.toStringAsFixed(2)} 付款后，代币将释放给买家。');
          if (confirmed == true) {
            final ok = await _logic.doConfirmRelease(order);
            if (ok) Get.back();
          }
        },
      ));
    }

    // Seller: cancel open order
    if (order.status == P2POrder.open && _isSeller) {
      btns.add(_OutlineButton(
        label: '取消订单',
        color: Styles.c_8E9AB0,
        onTap: () async {
          final ok = await _logic.doCancel(order);
          if (ok) Get.back();
        },
      ));
    }

    // Buyer or seller: raise dispute (only when paid)
    if (order.status == P2POrder.paid) {
      btns.add(_OutlineButton(
        label: '发起申诉',
        color: const Color(0xFFEF4444),
        onTap: () async {
          final confirmed = await _showConfirmDialog(
              context, '发起申诉？', '申诉后订单将冻结，由平台仲裁。请确保有充分证据（付款截图等）。');
          if (confirmed == true) {
            final ok = await _logic.doRaiseDispute(order);
            if (ok) Get.back();
          }
        },
      ));
    }

    if (btns.isEmpty) return const SizedBox.shrink();

    return Column(
      children: btns
          .map((b) => Padding(padding: EdgeInsets.only(bottom: 12.h), child: b))
          .toList(),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String content) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
          ],
        ),
      );
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: child,
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Text(label,
                  style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: Styles.c_0C1C33,
                      fontWeight: valueBold ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: Styles.c_E8EAEF),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            elevation: 0,
          ),
          child: Text(label,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50.h,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        ),
      );
}
