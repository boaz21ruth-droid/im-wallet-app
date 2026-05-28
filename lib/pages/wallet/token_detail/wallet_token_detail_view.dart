import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/wallet_models.dart';
import '../wallet_logic.dart';
import '../send/wallet_send_view.dart';
import '../receive/wallet_receive_view.dart';

class WalletTokenDetailView extends StatefulWidget {
  final AssetBalance asset;
  const WalletTokenDetailView({super.key, required this.asset});

  @override
  State<WalletTokenDetailView> createState() => _WalletTokenDetailViewState();
}

class _WalletTokenDetailViewState extends State<WalletTokenDetailView> {
  WalletLogic get logic => Get.find<WalletLogic>();

  @override
  void initState() {
    super.initState();
    logic.loadTokenHistory(widget.asset);
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
          widget.asset.symbol,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Styles.c_0C1C33),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => logic.loadTokenHistory(widget.asset),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildBalanceCard()),
            SliverToBoxAdapter(child: _buildActionButtons()),
            SliverToBoxAdapter(child: _buildHistoryHeader()),
            _buildHistoryList(),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Obx(() {
      final price = logic.coinPrices[widget.asset.symbol]?.price ?? 0;
      return Container(
        margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF005BB3), Color(0xFF1E88E5), Color(0xFF4EDEA3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF005BB3).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatBalance(widget.asset.balance),
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              widget.asset.symbol,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14.sp),
            ),
            if (price > 0) ...[
              SizedBox(height: 8.h),
              Text(
                '≈ \$${(widget.asset.balance * price).toStringAsFixed(2)} USD',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13.sp),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              icon: Icons.call_made,
              label: '发送',
              color: Styles.c_0089FF,
              onTap: () => Get.to(() => WalletSendView(prefillAsset: widget.asset)),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _ActionBtn(
              icon: Icons.call_received,
              label: '接收',
              color: const Color(0xFF4EDEA3),
              onTap: () => Get.to(() => const WalletReceiveView()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
      child: Text(
        '交易记录',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Styles.c_0C1C33),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Obx(() {
      if (logic.isLoadingTokenHistory.value) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
        );
      }
      final records = logic.tokenHistory;
      if (records.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.h),
            child: Center(
              child: Text(
                '暂无交易记录',
                style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
              ),
            ),
          ),
        );
      }
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) {
              final tx = records[i];
              final isFirst = i == 0;
              final isLast = i == records.length - 1;
              return _buildTxRow(tx, isFirst: isFirst, isLast: isLast);
            },
            childCount: records.length,
          ),
        ),
      );
    });
  }

  Widget _buildTxRow(TxRecord tx, {required bool isFirst, required bool isLast}) {
    final myAddr = logic.currentAddress.toLowerCase();
    final isSend = tx.from.toLowerCase() == myAddr;
    final amount = _formatTxAmount(tx);

    return GestureDetector(
      onTap: () => _openExplorer(tx.hash),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? Radius.circular(16.r) : Radius.zero,
            bottom: isLast ? Radius.circular(16.r) : Radius.zero,
          ),
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Styles.c_E8EAEF, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: (isSend ? Colors.orange : Colors.green).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                isSend ? Icons.call_made : Icons.call_received,
                color: isSend ? Colors.orange : Colors.green,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSend ? '发送' : '接收',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Styles.c_0C1C33,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    tx.shortHash,
                    style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isSend ? '-' : '+'}$amount ${widget.asset.symbol}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isSend ? Colors.orange : Colors.green,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _formatDate(tx.timestamp),
                  style: TextStyle(fontSize: 11.sp, color: Styles.c_8E9AB0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExplorer(String hash) async {
    final chainKey = logic.selectedChainKey.value;
    final base = chains[chainKey]?.txExplorerBase;
    if (base == null || hash.isEmpty) return;
    final uri = Uri.parse('$base$hash');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTxAmount(TxRecord tx) {
    if (tx.value == BigInt.zero) return '0';
    final v = tx.value.toDouble() / BigInt.from(10).pow(tx.decimals).toDouble();
    if (v < 0.000001) return v.toStringAsExponential(4);
    if (v < 1) return v.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return v.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _formatBalance(double v) {
    if (v == 0) return '0';
    if (v < 0.000001) return v.toStringAsExponential(4);
    if (v < 1) return v.toStringAsFixed(6);
    return v.toStringAsFixed(4);
  }

  String _formatDate(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18.w),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
