// lib/pages/wallet/swap/swap_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/swap/swap_config.dart';
import '../../../services/wallet/swap/swap_models.dart';
import '../../../services/wallet/wallet_models.dart';
import 'swap_logic.dart';
import 'swap_result_view.dart';
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
            if (kZeroxApiKey.isEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text('Swap 未配置，请联系运营',
                    style: TextStyle(
                        color: Colors.red[700], fontSize: 13.sp)),
              ),
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

class _SellCard extends StatefulWidget {
  final SwapLogic logic;
  const _SellCard({required this.logic});

  @override
  State<_SellCard> createState() => _SellCardState();
}

class _SellCardState extends State<_SellCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.logic.sellAmountText.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  AssetBalance? _balanceFor(SwapToken? t) {
    if (t == null) return null;
    for (final b in widget.logic.wallet.currentChainBalances) {
      if (b.symbol == t.symbol && b.contractAddress == t.contractAddress) {
        return b;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final logic = widget.logic;
    return Obx(() {
      final t = logic.sellToken.value;
      final bal = _balanceFor(t);
      final balanceText = t == null ? null : (bal?.balance.toString() ?? '0');

      // Keep controller in sync with logic.sellAmountText without resetting
      // the cursor when the texts already match.
      final txt = logic.sellAmountText.value;
      if (_ctrl.text != txt) {
        _ctrl.value = TextEditingValue(
          text: txt,
          selection: TextSelection.collapsed(offset: txt.length),
        );
      }

      return _TokenCard(
        label: '支付',
        balanceText: balanceText,
        amountController: _ctrl,
        readOnly: false,
        token: t,
        amountValue: txt,
        onAmountChanged: logic.onAmountInput,
        onPickToken: () async {
          final picked = await showTokenPickerSheet(
              context, TokenPickerSide.sell);
          if (picked != null) logic.selectSellToken(picked);
        },
        onMax: (t == null || bal == null)
            ? null
            : () {
                // Use raw BigInt balance — round-trips through
                // parseDecimalAmount without floating-point drift.
                final precise = _formatBigIntFull(bal.rawBalance, bal.decimals);
                logic.onAmountInput(precise);
              },
      );
    });
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

/// Builds a TextField fallback controller. Only reached when no controller
/// is supplied and the field is editable — after the C1 fix, this path is
/// unreachable in normal usage (the sell card always supplies a controller
/// and the buy card is read-only). Kept defensively.
TextEditingController _fallbackController(String text) {
  return TextEditingController(text: text)
    ..selection = TextSelection.collapsed(offset: text.length);
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
                child: readOnly
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Text(
                          amountValue.isEmpty ? '0.0' : amountValue,
                          style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                              color: amountValue.isEmpty
                                  ? Styles.c_8E9AB0
                                  : Styles.c_0C1C33),
                        ),
                      )
                    : TextField(
                        controller: amountController ??
                            _fallbackController(amountValue),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]')),
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
      final enabled = text == 'Swap' || text.startsWith('授权');
      return SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: enabled ? () => _onTap(context) : null,
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

  void _onTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Styles.c_FFFFFF,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _PasswordSheet(logic: logic),
    );
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
    if (logic.needsApproval.value == true) {
      return '授权 ${logic.sellToken.value!.symbol}';
    }
    return 'Swap';
  }
}

class _PasswordSheet extends StatefulWidget {
  final SwapLogic logic;
  const _PasswordSheet({required this.logic});

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _pwdCtrl = TextEditingController();

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    Get.back(); // close password sheet first
    EasyLoading.show(status: '提交中...');
    final result = await widget.logic.executeSwap(password: _pwdCtrl.text);
    EasyLoading.dismiss();
    Get.off(() => SwapResultView(
          success: result.ok,
          txHash: result.txHash,
          chainKey: result.chainKey,
          errorMessage: result.error,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20.w, 20.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确认 Swap',
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Styles.c_0C1C33)),
          SizedBox(height: 12.h),
          Text('输入钱包密码确认',
              style:
                  TextStyle(fontSize: 14.sp, color: Styles.c_8E9AB0)),
          SizedBox(height: 8.h),
          TextField(
            controller: _pwdCtrl,
            obscureText: true,
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: '钱包密码',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.c_0089FF,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: Text('确认',
                  style: TextStyle(
                      fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
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

/// Full-precision formatter — does NOT trim trailing zeros or cap fraction
/// length. Inverse of [SwapLogic.parseDecimalAmount], so round-tripping
/// raw <-> string preserves every wei. Used for the MAX button so the
/// resulting parse matches the original BigInt exactly.
String _formatBigIntFull(BigInt raw, int decimals) {
  if (raw == BigInt.zero) return '0';
  if (decimals == 0) return raw.toString();
  final divisor = BigInt.from(10).pow(decimals);
  final whole = raw ~/ divisor;
  final frac = raw - whole * divisor;
  final fracStr = frac.toString().padLeft(decimals, '0');
  return '$whole.$fracStr';
}
