import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/wallet/chain_config.dart';
import '../wallet_logic.dart';
import 'p2p_logic.dart';

// USDT contract on BSC Testnet
const _usdtBscTestnet = '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd';

class P2PCreatePage extends StatefulWidget {
  const P2PCreatePage({super.key});

  @override
  State<P2PCreatePage> createState() => _P2PCreatePageState();
}

class _P2PCreatePageState extends State<P2PCreatePage> {
  final _amountCtrl  = TextEditingController();
  final _priceCtrl   = TextEditingController();
  String _payMethod  = '支付宝';
  int    _lockMins   = 30;

  final _payMethods  = ['支付宝', '微信', '银行卡'];
  final _lockOptions = [15, 30, 45, 60];

  P2PLogic get _logic => Get.find<P2PLogic>();

  double get _usdtAmount => double.tryParse(_amountCtrl.text) ?? 0;
  double get _unitPrice  => double.tryParse(_priceCtrl.text)  ?? 0;
  double get _totalFiat  => _usdtAmount * _unitPrice;

  // Get current USDT balance on BSC testnet
  String get _myAddress => Get.find<WalletLogic>().currentAddress;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_usdtAmount <= 0) {
      IMViews.showToast('请输入出售数量');
      return;
    }
    if (_unitPrice <= 0) {
      IMViews.showToast('请输入单价');
      return;
    }

    // BSC Testnet USDT has 18 decimals (unlike mainnet's 6)
    final amountRaw  = BigInt.from((_usdtAmount * 1e18).round());
    final fiatCents  = (_totalFiat * 100).round();

    final ok = await _logic.doCreateOrder(
      usdtContract: _usdtBscTestnet,
      amount:       amountRaw,
      fiatAmount:   fiatCents,
      payMethod:    _payMethod,
      lockMinutes:  _lockMins,
    );
    if (ok && mounted) Get.back(result: true);
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
        title: Text('发布出售',
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
            _buildSection('出售代币', _buildTokenSelector()),
            SizedBox(height: 16.h),
            _buildSection('出售数量', _buildAmountInput()),
            SizedBox(height: 16.h),
            _buildSection('单价 (CNY/USDT)', _buildPriceInput()),
            SizedBox(height: 16.h),
            _buildSection('收款方式', _buildPayMethodSelector()),
            SizedBox(height: 16.h),
            _buildSection('付款时限', _buildLockTimeSelector()),
            SizedBox(height: 16.h),
            _buildSummaryCard(),
            SizedBox(height: 24.h),
            _buildNotice(),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
                child: Text('授权并发布',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 13.sp,
                color: Styles.c_8E9AB0,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }

  Widget _buildTokenSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: const Color(0xFF26A17B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('₮',
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF26A17B))),
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('USDT',
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Styles.c_0C1C33)),
              Text('BEP20 · BSC Testnet',
                  style: TextStyle(fontSize: 11.sp, color: Styles.c_8E9AB0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: TextStyle(fontSize: 16.sp, color: Styles.c_0C1C33),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(color: Styles.c_8E9AB0),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Text('USDT',
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Styles.c_8E9AB0,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Text('¥',
              style: TextStyle(
                  fontSize: 18.sp,
                  color: Styles.c_0C1C33,
                  fontWeight: FontWeight.w600)),
          SizedBox(width: 6.w),
          Expanded(
            child: TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: TextStyle(fontSize: 16.sp, color: Styles.c_0C1C33),
              decoration: InputDecoration(
                hintText: '7.20',
                hintStyle: TextStyle(color: Styles.c_8E9AB0),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Text('CNY',
              style: TextStyle(
                  fontSize: 14.sp,
                  color: Styles.c_8E9AB0,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPayMethodSelector() {
    return Row(
      children: _payMethods.map((m) {
        final isSelected = _payMethod == m;
        Color color = Styles.c_8E9AB0;
        if (m == '支付宝') color = const Color(0xFF1677FF);
        if (m == '微信') color = const Color(0xFF07C160);
        if (m == '银行卡') color = const Color(0xFFFF9F40);
        return GestureDetector(
          onTap: () => setState(() => _payMethod = m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(right: 10.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Styles.c_FFFFFF,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected ? color : Styles.c_E8EAEF,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(m,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: isSelected ? color : Styles.c_8E9AB0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLockTimeSelector() {
    return Row(
      children: _lockOptions.map((mins) {
        final isSelected = _lockMins == mins;
        return GestureDetector(
          onTap: () => setState(() => _lockMins = mins),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(right: 10.w),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? Styles.c_0089FF.withValues(alpha: 0.1)
                  : Styles.c_FFFFFF,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected ? Styles.c_0089FF : Styles.c_E8EAEF,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text('$mins 分',
                style: TextStyle(
                    fontSize: 13.sp,
                    color: isSelected ? Styles.c_0089FF : Styles.c_8E9AB0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCard() {
    if (_usdtAmount <= 0 || _unitPrice <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_0089FF.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_0089FF.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('出售 USDT',
                  style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0)),
              Text('${_usdtAmount.toStringAsFixed(2)} USDT',
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Styles.c_0C1C33)),
            ],
          ),
          Icon(Icons.arrow_forward, color: Styles.c_0089FF, size: 20.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('收款',
                  style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0)),
              Text('¥${_totalFiat.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '发布前需要两步链上操作：① 授权合约使用 USDT ② 锁入 USDT。过程中需要支付少量 BNB 作为 gas 费。',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
