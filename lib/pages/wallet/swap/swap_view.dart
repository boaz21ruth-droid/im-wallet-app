// lib/pages/wallet/swap/swap_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/swap/swap_models.dart';
import 'swap_logic.dart';
import 'token_picker_sheet.dart';

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
        title: Text('闪兑',
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Styles.c_0C1C33)),
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
            _buildChainChip(logic),
            SizedBox(height: 16.h),
            _SellCard(logic: logic),
            SizedBox(height: 12.h),
            _buildInvertButton(logic),
            SizedBox(height: 12.h),
            _BuyCard(logic: logic),
            SizedBox(height: 20.h),
            _QuoteSummary(logic: logic),
            SizedBox(height: 24.h),
            _MainButton(logic: logic),
          ],
        ),
      ),
    );
  }

  Widget _buildChainChip(SwapLogic logic) {
    return Obx(() {
      final key = logic.swapChainKey.value;
      final cfg = chains[key];
      return GestureDetector(
        onTap: () {
          // Chain picker bottom sheet — added in Task 5; static for now.
        },
        child: Container(
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
        ),
      );
    });
  }

  Widget _buildInvertButton(SwapLogic logic) {
    return Center(
      child: GestureDetector(
        onTap: logic.invertTokens,
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            shape: BoxShape.circle,
            border: Border.all(color: Styles.c_E8EAEF),
          ),
          child: Icon(Icons.swap_vert, color: Styles.c_0089FF, size: 22.w),
        ),
      ),
    );
  }
}

class _SellCard extends StatelessWidget {
  final SwapLogic logic;
  const _SellCard({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = logic.sellToken.value;
      final balance = _balanceFor(logic, t);
      return _TokenCard(
        label: '支付',
        balanceText: balance,
        amountController: null,
        readOnly: false,
        token: t,
        amountValue: logic.sellAmountText.value,
        onAmountChanged: logic.onAmountInput,
        onPickToken: () async {
          final picked = await showTokenPickerSheet(
              context, TokenPickerSide.sell);
          if (picked != null) logic.selectSellToken(picked);
        },
        onMax: t == null
            ? null
            : () {
                final bal = balance;
                if (bal != null) logic.onAmountInput(bal);
              },
      );
    });
  }

  String? _balanceFor(SwapLogic logic, SwapToken? t) {
    if (t == null) return null;
    for (final b in logic.wallet.currentChainBalances) {
      if (b.symbol == t.symbol && b.contractAddress == t.contractAddress) {
        return b.balance.toString();
      }
    }
    return '0';
  }
}

class _BuyCard extends StatelessWidget {
  final SwapLogic logic;
  const _BuyCard({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = logic.buyToken.value;
      final priceR = logic.priceResult.value;
      String amountStr = '';
      if (priceR != null && t != null) {
        amountStr =
            _formatBigInt(priceR.buyAmount, t.decimals);
      }
      return _TokenCard(
        label: '获得',
        balanceText: null,
        amountController: null,
        readOnly: true,
        token: t,
        amountValue: amountStr,
        onAmountChanged: (_) {},
        onPickToken: () async {
          final picked = await showTokenPickerSheet(
              context, TokenPickerSide.buy);
          if (picked != null) logic.selectBuyToken(picked);
        },
        onMax: null,
      );
    });
  }
}

class _TokenCard extends StatelessWidget {
  final String label;
  final String? balanceText;
  final TextEditingController? amountController;
  final bool readOnly;
  final SwapToken? token;
  final String amountValue;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onPickToken;
  final VoidCallback? onMax;

  const _TokenCard({
    required this.label,
    required this.balanceText,
    required this.amountController,
    required this.readOnly,
    required this.token,
    required this.amountValue,
    required this.onAmountChanged,
    required this.onPickToken,
    required this.onMax,
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
              if (balanceText != null)
                Text('余额: $balanceText',
                    style: TextStyle(
                        fontSize: 13.sp, color: Styles.c_8E9AB0)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  enabled: !readOnly,
                  controller: amountController ??
                      TextEditingController(text: amountValue)
                    ..selection = TextSelection.collapsed(
                        offset: amountValue.length),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: Styles.c_0C1C33),
                  decoration: const InputDecoration(
                    hintText: '0.0',
                    border: InputBorder.none,
                  ),
                  onChanged: onAmountChanged,
                ),
              ),
              if (onMax != null)
                TextButton(
                  onPressed: onMax,
                  child: Text('MAX',
                      style: TextStyle(
                          color: Styles.c_0089FF, fontSize: 12.sp)),
                ),
              GestureDetector(
                onTap: onPickToken,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Styles.c_F8F9FA,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Text(token?.symbol ?? '选择代币',
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteSummary extends StatelessWidget {
  final SwapLogic logic;
  const _QuoteSummary({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = logic.priceResult.value;
      final sell = logic.sellToken.value;
      final buy = logic.buyToken.value;
      if (r == null || sell == null || buy == null) {
        return const SizedBox.shrink();
      }
      final sellAmt = logic.sellAmountRaw;
      final rate = sellAmt == BigInt.zero
          ? '-'
          : '${_formatBigInt(r.buyAmount, buy.decimals)} ${buy.symbol} / '
              '${_formatBigInt(sellAmt, sell.decimals)} ${sell.symbol}';
      final feeAmt = r.fees.integratorFeeAmount;
      return Column(
        children: [
          _row('报价方', '0x'),
          _row('汇率', rate),
          _row('滑点', '${(logic.slippageBps.value / 100).toStringAsFixed(2)}%'),
          if (feeAmt != null)
            _row('平台费',
                '0.30% (${_formatBigInt(feeAmt, buy.decimals)} ${buy.symbol})'),
        ],
      );
    });
  }

  Widget _row(String label, String value) {
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

class _MainButton extends StatelessWidget {
  final SwapLogic logic;
  const _MainButton({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final text = _resolveText(logic);
      final enabled = text == 'Swap';
      return SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: enabled ? () {} : null, // wired in Task 3
          style: ElevatedButton.styleFrom(
            backgroundColor: Styles.c_0089FF,
            disabledBackgroundColor: Styles.c_8E9AB0,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            elevation: 0,
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.w600)),
        ),
      );
    });
  }

  String _resolveText(SwapLogic logic) {
    if (logic.sellToken.value == null || logic.buyToken.value == null) {
      return '选择代币';
    }
    if (logic.sellAmountRaw == BigInt.zero) return '输入金额';
    if (logic.isFetchingPrice.value) return '查询报价中…';
    final err = logic.lastError.value;
    if (err != null) {
      switch (err.kind) {
        case SwapErrorKind.noApiKey:
          return 'Swap 未配置';
        case SwapErrorKind.noLiquidity:
          return '无可用路由';
        case SwapErrorKind.chainNotSupported:
          return '该链暂不支持 Swap';
        case SwapErrorKind.network:
          return '网络异常';
        case SwapErrorKind.rateLimited:
          return '请求过频';
        default:
          return '报价失败';
      }
    }
    if (logic.priceResult.value == null) return '输入金额';
    return 'Swap';
  }
}

String _formatBigInt(BigInt raw, int decimals) {
  if (raw == BigInt.zero) return '0';
  final divisor = BigInt.from(10).pow(decimals);
  final whole = raw ~/ divisor;
  final frac = raw - whole * divisor;
  if (frac == BigInt.zero) return whole.toString();
  var fracStr = frac.toString().padLeft(decimals, '0');
  // Trim trailing zeros, max 6 decimals shown
  fracStr = fracStr.length > 6 ? fracStr.substring(0, 6) : fracStr;
  fracStr = fracStr.replaceFirst(RegExp(r'0+$'), '');
  if (fracStr.isEmpty) return whole.toString();
  return '$whole.$fracStr';
}
