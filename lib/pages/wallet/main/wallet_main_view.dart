import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/wallet_models.dart';
import '../wallet_logic.dart';
import '../receive/wallet_receive_view.dart';
import '../send/wallet_send_view.dart';
import '../swap/swap_binding.dart';
import '../swap/swap_view.dart';
import '../token_detail/wallet_token_detail_view.dart';

class WalletMainView extends StatelessWidget {
  const WalletMainView({super.key});

  WalletLogic get logic => Get.find<WalletLogic>();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await logic.refreshBalances();
        await logic.refreshPrices();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAssetCard()),
          SliverToBoxAdapter(child: _buildActionButtons()),
          SliverToBoxAdapter(child: _buildChainSelector()),
          SliverToBoxAdapter(child: _buildBalanceList()),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }

  Widget _buildAssetCard() {
    return Obx(() {
      final total = logic.totalUsd;
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
              color: const Color(0xFF005BB3).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Obx(() => Text(
                    logic.selectedAccount.value?.name ?? 'Account',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13.sp,
                    ),
                  )),
                ),
                _ChainBadge(),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              '\$${_formatAmount(total)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Total Balance',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13.sp),
            ),
            SizedBox(height: 16.h),
            _buildAddressRow(),
          ],
        ),
      );
    });
  }

  Widget _buildAddressRow() {
    return Obx(() {
      final addr = logic.currentAddress;
      if (addr.isEmpty) return const SizedBox.shrink();
      final short = addr.length > 20
          ? '${addr.substring(0, 10)}...${addr.substring(addr.length - 8)}'
          : addr;
      return GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: addr));
          EasyLoading.showToast('地址已复制');
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                short,
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.copy, color: Colors.white.withOpacity(0.7), size: 14.w),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionBtn(
            icon: Icons.call_made,
            label: '发送',
            color: Styles.c_0089FF,
            onTap: () => Get.to(() => const WalletSendView()),
          ),
          _ActionBtn(
            icon: Icons.call_received,
            label: '接收',
            color: const Color(0xFF4EDEA3),
            onTap: () => Get.to(() => const WalletReceiveView()),
          ),
          _ActionBtn(
            icon: Icons.swap_horiz,
            label: 'Swap',
            color: const Color(0xFFFF9F40),
            onTap: () => Get.to(
              () => const SwapView(),
              binding: SwapBinding(),
            ),
          ),
          _ActionBtn(
            icon: Icons.lock_outline,
            label: '锁定',
            color: Styles.c_8E9AB0,
            onTap: logic.lockWallet,
          ),
        ],
      ),
    );
  }

  Widget _buildChainSelector() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Row(
            children: [
              Text(
                '资产',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33,
                ),
              ),
              const Spacer(),
              Text(
                'Testnet',
                style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
              ),
              SizedBox(width: 4.w),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: logic.settings.value.testnetMode,
                  onChanged: (_) => logic.toggleTestnetMode(),
                  activeThumbColor: const Color(0xFFFF9800),
                  activeTrackColor: const Color(0xFFFF9800).withAlpha(100),
                ),
              ),
            ],
          )),
          SizedBox(height: 12.h),
          Obx(() {
            final effectiveKeys = logic.effectiveEnabledChainKeys;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: effectiveKeys.map((key) {
                  final cfg = chains[key]!;
                  final isSelected = logic.selectedChainKey.value == key;
                  return GestureDetector(
                    onTap: () => logic.switchChain(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Styles.c_0089FF : Styles.c_FFFFFF,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? Styles.c_0089FF : Styles.c_E8EAEF,
                        ),
                      ),
                      child: Text(
                        cfg.name,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isSelected ? Colors.white : Styles.c_8E9AB0,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBalanceList() {
    return Obx(() {
      final isLoading = logic.isLoadingBalances.value;
      if (isLoading) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      final items = logic.currentChainBalances;
      if (items.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: Text('暂无资产', style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp)),
          ),
        );
      }
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final b = entry.value;
              return GestureDetector(
                onTap: () => Get.to(() => WalletTokenDetailView(asset: b)),
                child: _buildBalanceRow(b, isLast: i == items.length - 1),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildBalanceRow(AssetBalance b, {required bool isLast}) {
    final price = logic.coinPrices[b.symbol]?.price ?? 0;
    final change = logic.coinPrices[b.symbol]?.change24h ?? 0;
    final isPositive = change >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Styles.c_E8EAEF, width: 0.5)),
      ),
      child: Row(
        children: [
          _TokenIcon(symbol: b.symbol),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.symbol,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Styles.c_0C1C33,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  price > 0
                      ? '\$${_formatAmount(price)} ${_changeText(change)}'
                      : '-',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: price > 0
                        ? (isPositive ? Colors.green : Colors.red)
                        : Styles.c_8E9AB0,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatBalance(b.balance),
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                price > 0 ? '\$${_formatAmount(b.balance * price)}' : '-',
                style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1000) return v.toStringAsFixed(2);
    return v.toStringAsFixed(v < 1 ? 6 : 2);
  }

  String _formatBalance(double v) {
    if (v == 0) return '0';
    if (v < 0.000001) return v.toStringAsExponential(4);
    if (v < 1) return v.toStringAsFixed(6);
    return v.toStringAsFixed(4);
  }

  String _changeText(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)}%';
  }
}

class _ChainBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logic = Get.find<WalletLogic>();
    return Obx(() {
      final key = logic.selectedChainKey.value;
      final config = chains[key];
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          config?.name ?? key.toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      );
    });
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
      child: Column(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
          ),
        ],
      ),
    );
  }
}

class _TokenIcon extends StatelessWidget {
  final String symbol;
  const _TokenIcon({required this.symbol});

  static const _colors = {
    'ETH': Color(0xFF627EEA),
    'BNB': Color(0xFFF0B90B),
    'POL': Color(0xFF8247E5),
    'TRX': Color(0xFFEB0029),
    'USDT': Color(0xFF26A17B),
    'USDC': Color(0xFF2775CA),
    'BTC': Color(0xFFF7931A),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[symbol] ?? Styles.c_8E9AB0;
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          symbol.substring(0, symbol.length.clamp(0, 3)),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
