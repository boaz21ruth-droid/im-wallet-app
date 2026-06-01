// lib/pages/wallet/swap/token_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/swap/swap_models.dart';
import 'swap_logic.dart';

enum TokenPickerSide { sell, buy }

/// Returns the selected token, or null if dismissed.
Future<SwapToken?> showTokenPickerSheet(
    BuildContext context, TokenPickerSide side) async {
  final logic = Get.find<SwapLogic>();
  return showModalBottomSheet<SwapToken>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Styles.c_FFFFFF,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => _TokenPickerSheet(logic: logic, side: side),
  );
}

class _TokenPickerSheet extends StatelessWidget {
  final SwapLogic logic;
  final TokenPickerSide side;
  const _TokenPickerSheet({required this.logic, required this.side});

  List<SwapToken> _candidates() {
    // Buy side lives on the dest chain for cross-chain; sell side on the source.
    final chainKey = side == TokenPickerSide.buy
        ? logic.buyChainKey
        : logic.swapChainKey.value;
    final cfg = chains[chainKey];
    if (cfg == null) return const [];

    if (side == TokenPickerSide.sell) {
      // From: only what the user actually holds on the *swap* chain — not the
      // wallet main page's chain. Avoids the "余额 0" bug when the two diverge.
      final held = logic.wallet
          .balancesForChain(chainKey)
          .map((b) => SwapToken(
                chainKey: chainKey,
                symbol: b.symbol,
                decimals: b.decimals,
                contractAddress: b.contractAddress,
              ))
          .toList();
      return held;
    }

    // To: native + builtin tokens + custom tokens user added.
    final tokens = <SwapToken>[
      SwapToken(
        chainKey: chainKey,
        symbol: cfg.symbol,
        decimals: cfg.decimals,
      ),
      ...cfg.builtinTokens.map((t) => SwapToken(
            chainKey: chainKey,
            symbol: t.symbol,
            decimals: t.decimals,
            contractAddress: t.contractAddress,
          )),
      ...logic.wallet.settings.value.customTokens
          .where((c) => c.chainKey == chainKey)
          .map((c) => SwapToken(
                chainKey: chainKey,
                symbol: c.symbol,
                decimals: c.decimals,
                contractAddress: c.contractAddress,
              )),
    ];

    // Don't allow picking the same token as sell side.
    final excluded = logic.sellToken.value;
    return tokens.where((t) => t != excluded).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _candidates();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
      child: Column(
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
          Text(side == TokenPickerSide.sell ? '选择支付代币' : '选择获得代币',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: Styles.c_0C1C33)),
          SizedBox(height: 12.h),
          Expanded(
            child: tokens.isEmpty
                ? Center(
                    child: Text(
                        side == TokenPickerSide.sell
                            ? '当前链无持仓资产'
                            : '该链暂无可选代币',
                        style: TextStyle(
                            fontSize: 14.sp, color: Styles.c_8E9AB0)),
                  )
                : ListView.builder(
                    itemCount: tokens.length,
                    itemBuilder: (_, i) {
                      final t = tokens[i];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4.h),
                        leading: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color:
                                Styles.c_0089FF.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              t.symbol.substring(
                                  0, t.symbol.length.clamp(0, 3)),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Styles.c_0089FF,
                              ),
                            ),
                          ),
                        ),
                        title: Text(t.symbol,
                            style: TextStyle(
                                fontSize: 15.sp,
                                color: Styles.c_0C1C33,
                                fontWeight: FontWeight.w600)),
                        subtitle: t.contractAddress != null
                            ? Text(
                                _shortAddr(t.contractAddress!),
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Styles.c_8E9AB0),
                              )
                            : Text('原生代币',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Styles.c_8E9AB0)),
                        onTap: () => Get.back(result: t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _shortAddr(String a) =>
      a.length > 12 ? '${a.substring(0, 6)}…${a.substring(a.length - 4)}' : a;
}
