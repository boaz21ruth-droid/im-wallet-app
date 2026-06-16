import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import '../wallet_logic.dart';
import 'p2p_create_page.dart';
import 'p2p_logic.dart';
import 'p2p_models.dart';
import 'p2p_order_detail_page.dart';

class P2PHallPage extends StatefulWidget {
  const P2PHallPage({super.key});

  @override
  State<P2PHallPage> createState() => _P2PHallPageState();
}

class _P2PHallPageState extends State<P2PHallPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late P2PLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = Get.put(P2PLogic());
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 0 && _logic.openOrders.isEmpty) _logic.refreshHall();
      if (_tab.index == 1) _logic.refreshMine();
    });
    _logic.refreshHall();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
        title: Text('P2P 交易',
            style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Styles.c_0C1C33)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Styles.c_0089FF, size: 24.w),
            onPressed: () async {
              final ok = await Get.to(() => const P2PCreatePage());
              if (ok == true) {
                _tab.animateTo(1);
                _logic.refreshMine();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(44.h),
          child: TabBar(
            controller: _tab,
            indicatorColor: Styles.c_0089FF,
            indicatorWeight: 2.5,
            labelColor: Styles.c_0089FF,
            unselectedLabelColor: Styles.c_8E9AB0,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: '大厅'), Tab(text: '我的')],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _HallTab(logic: _logic),
          _MyOrdersTab(logic: _logic),
        ],
      ),
    );
  }
}

// ── Hall Tab ──────────────────────────────────────────────────────────────────

class _HallTab extends StatelessWidget {
  final P2PLogic logic;
  const _HallTab({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (logic.isLoadingHall.value && logic.openOrders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (logic.openOrders.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: 48.w, color: Styles.c_8E9AB0),
              SizedBox(height: 12.h),
              Text('暂无挂单', style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp)),
              SizedBox(height: 16.h),
              TextButton(onPressed: logic.refreshHall, child: const Text('刷新')),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: logic.refreshHall,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          itemCount: logic.openOrders.length,
          itemBuilder: (_, i) => _OrderCard(
            order: logic.openOrders[i],
            isMine: false,
            onTap: () => Get.to(() => P2POrderDetailPage(order: logic.openOrders[i])),
          ),
        ),
      );
    });
  }
}

// ── My Orders Tab ─────────────────────────────────────────────────────────────

class _MyOrdersTab extends StatelessWidget {
  final P2PLogic logic;
  const _MyOrdersTab({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (logic.isLoadingMine.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final all = [...logic.mySellingOrders, ...logic.myBuyingOrders]
        ..sort((a, b) => b.orderId.compareTo(a.orderId));
      if (all.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 48.w, color: Styles.c_8E9AB0),
              SizedBox(height: 12.h),
              Text('暂无订单', style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp)),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: logic.refreshMine,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          itemCount: all.length,
          itemBuilder: (_, i) {
            final walletLogic = Get.find<WalletLogic>();
            final isMine = all[i].seller.toLowerCase() ==
                walletLogic.currentAddress.toLowerCase();
            return _OrderCard(
              order: all[i],
              isMine: isMine,
              onTap: () => Get.to(() => P2POrderDetailPage(order: all[i])),
            );
          },
        ),
      );
    });
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final P2POrder order;
  final bool isMine;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.isMine, required this.onTap});

  Color get _statusColor {
    switch (order.status) {
      case P2POrder.open:      return const Color(0xFF10B981);
      case P2POrder.locked:    return const Color(0xFFFF9F40);
      case P2POrder.paid:      return const Color(0xFF0089FF);
      case P2POrder.released:  return const Color(0xFF10B981);
      case P2POrder.cancelled: return const Color(0xFF8E9AB0);
      case P2POrder.disputed:  return const Color(0xFFEF4444);
      default:                 return Styles.c_8E9AB0;
    }
  }

  String get _statusText {
    switch (order.status) {
      case P2POrder.open:      return '待接单';
      case P2POrder.locked:    return '待付款';
      case P2POrder.paid:      return '待确认';
      case P2POrder.released:  return '已完成';
      case P2POrder.cancelled: return '已取消';
      case P2POrder.disputed:  return '申诉中';
      default:                 return order.statusLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: Styles.c_0089FF.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: Styles.c_0089FF, size: 18.w),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shortSeller,
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Styles.c_0C1C33),
                      ),
                      Text(
                        isMine ? '我发布的' : '卖家',
                        style: TextStyle(fontSize: 11.sp, color: Styles.c_8E9AB0),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _statusText,
                    style: TextStyle(
                        fontSize: 11.sp,
                        color: _statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // Price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '¥${order.fiatDisplay.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Styles.c_0C1C33),
                ),
                SizedBox(width: 8.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    '单价 ¥${order.unitPrice.toStringAsFixed(2)}/USDT',
                    style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              '数量 ${order.tokenDisplay.toStringAsFixed(2)} USDT',
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
            ),
            SizedBox(height: 10.h),
            // Pay method + action
            Row(
              children: [
                _PayChip(label: order.payMethod),
                const Spacer(),
                if (order.status == P2POrder.open && !isMine)
                  _ActionButton(
                    label: '立即购买',
                    color: Styles.c_0089FF,
                    onTap: onTap,
                  ),
                if (order.status == P2POrder.paid && isMine)
                  _ActionButton(
                    label: '确认放币',
                    color: const Color(0xFF10B981),
                    onTap: onTap,
                  ),
                if (order.status == P2POrder.locked && !isMine)
                  _ActionButton(
                    label: '标记已付款',
                    color: const Color(0xFFFF9F40),
                    onTap: onTap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String label;
  const _PayChip({required this.label});

  Color get _color {
    if (label.contains('支付宝')) return const Color(0xFF1677FF);
    if (label.contains('微信')) return const Color(0xFF07C160);
    return const Color(0xFFFF9F40);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.sp, color: _color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
