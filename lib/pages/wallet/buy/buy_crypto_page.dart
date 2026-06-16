import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/wallet/chain_config.dart';
import '../wallet_logic.dart';

// ── Provider definitions ──────────────────────────────────────────────────────

class _Provider {
  final String id;
  final String name;
  final String description;
  final String fees;
  final List<String> payMethods;
  final Color color;
  final IconData icon;

  const _Provider({
    required this.id,
    required this.name,
    required this.description,
    required this.fees,
    required this.payMethods,
    required this.color,
    required this.icon,
  });
}

const _providers = [
  _Provider(
    id: 'transak',
    name: 'Transak',
    description: '支持 150+ 国家，信用卡/银行卡购买',
    fees: '手续费约 1.5%',
    payMethods: ['信用卡', '借记卡', '银行转账'],
    color: Color(0xFF1A56DB),
    icon: Icons.credit_card,
  ),
  _Provider(
    id: 'moonpay',
    name: 'MoonPay',
    description: '全球覆盖，支持 Apple Pay/Google Pay',
    fees: '手续费约 2.5%',
    payMethods: ['信用卡', 'Apple Pay', 'Google Pay'],
    color: Color(0xFF7B3FE4),
    icon: Icons.payment,
  ),
];

// ── Chain → provider network/currency mapping ─────────────────────────────────

Map<String, String> _transakParams(String chainKey, String address) {
  const networkMap = {
    'eth': 'ethereum',
    'bsc': 'bsc',
    'polygon': 'polygon',
    'arbitrum': 'arbitrum',
    'optimism': 'optimism',
    'tron': 'tron',
  };
  final network = networkMap[chainKey] ?? 'ethereum';
  return {
    'apiKey': 'adb9ee9f-4f3c-4da8-9f87-6c8e8cd0a0e4', // public staging key
    'defaultCryptoCurrency': 'USDT',
    'walletAddress': address,
    'network': network,
    'productsAvailed': 'BUY',
    'disableWalletAddressForm': 'true',
    'themeColor': '0089FF',
  };
}

Map<String, String> _moonpayParams(String chainKey, String address) {
  const currencyMap = {
    'eth': 'eth',
    'bsc': 'bnb_bsc',
    'polygon': 'matic_polygon',
    'arbitrum': 'eth_arbitrum',
    'optimism': 'eth_optimism',
    'tron': 'trx',
  };
  return {
    'apiKey': 'pk_test_key', // replace with production key
    'currencyCode': currencyMap[chainKey] ?? 'eth',
    'walletAddress': address,
    'showWalletAddressForm': 'false',
    'colorCode': '%230089FF',
  };
}

Uri _buildUrl(String providerId, String chainKey, String address) {
  if (providerId == 'moonpay') {
    return Uri.https('buy-sandbox.moonpay.com', '/', _moonpayParams(chainKey, address));
  }
  // Transak staging
  return Uri.https('global-stg.transak.com', '/', _transakParams(chainKey, address));
}

// ── Page ──────────────────────────────────────────────────────────────────────

class BuyCryptoPage extends StatefulWidget {
  const BuyCryptoPage({super.key});

  @override
  State<BuyCryptoPage> createState() => _BuyCryptoPageState();
}

class _BuyCryptoPageState extends State<BuyCryptoPage> {
  final logic = Get.find<WalletLogic>();
  String? _selectedProviderId;

  String get _chainKey => logic.selectedChainKey.value;
  String get _address => logic.currentAddress;

  Future<void> _launch(String providerId) async {
    if (_address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到钱包地址')),
      );
      return;
    }
    final uri = _buildUrl(providerId, _chainKey, _address);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
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
          onPressed: () => Get.back(),
        ),
        title: Text(
          '买币',
          style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Styles.c_0C1C33),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressCard(),
            SizedBox(height: 24.h),
            Text(
              '选择支付服务商',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Styles.c_8E9AB0,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10.h),
            ..._providers.map((p) => _buildProviderCard(p)),
            SizedBox(height: 16.h),
            _buildNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Obx(() {
      final addr = logic.currentAddress;
      final cfg = chains[logic.selectedChainKey.value];
      final short = addr.length > 20
          ? '${addr.substring(0, 12)}...${addr.substring(addr.length - 8)}'
          : addr;
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Styles.c_E8EAEF),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Styles.c_0089FF.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.account_balance_wallet_outlined,
                  color: Styles.c_0089FF, size: 22.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '收款地址（${cfg?.name ?? ''}）',
                    style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    addr.isEmpty ? '未创建钱包' : short,
                    style: TextStyle(
                        fontSize: 13.sp,
                        color: Styles.c_0C1C33,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              cfg?.symbol ?? '',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: Styles.c_0089FF,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProviderCard(_Provider provider) {
    final isSelected = _selectedProviderId == provider.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedProviderId = provider.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? Styles.c_0089FF : Styles.c_E8EAEF,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: provider.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(provider.icon, color: provider.color, size: 20.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Styles.c_0C1C33),
                      ),
                      Text(
                        provider.fees,
                        style:
                            TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Styles.c_0089FF, size: 22.w)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: Styles.c_E8EAEF, size: 22.w),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              provider.description,
              style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: provider.payMethods
                  .map((m) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Styles.c_F8F9FA,
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Styles.c_E8EAEF),
                        ),
                        child: Text(m,
                            style: TextStyle(
                                fontSize: 11.sp, color: Styles.c_8E9AB0)),
                      ))
                  .toList(),
            ),
            if (isSelected) ...[
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  onPressed: () => _launch(provider.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.c_0089FF,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '前往 ${provider.name} 购买',
                    style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
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
              '买币服务由第三方提供商完成，需完成 KYC 实名认证。购买的加密货币将直接发送到您的钱包地址。',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}
