import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletTransferBubble extends StatelessWidget {
  final String amount;
  final String symbol;
  final String chain;
  final String hash;
  final bool isSentByMe;

  const WalletTransferBubble({
    super.key,
    required this.amount,
    required this.symbol,
    required this.chain,
    required this.hash,
    required this.isSentByMe,
  });

  factory WalletTransferBubble.fromJson(
    Map<String, dynamic> d, {
    required bool isSentByMe,
  }) {
    return WalletTransferBubble(
      amount: d['amount'] as String? ?? '',
      symbol: d['symbol'] as String? ?? '',
      chain: d['chain'] as String? ?? '',
      hash: d['hash'] as String? ?? '',
      isSentByMe: isSentByMe,
    );
  }

  String get _displayText =>
      isSentByMe ? '已转账 $amount $symbol' : '收到 $amount $symbol';

  String get _chainLabel {
    const names = {
      'eth': 'Ethereum',
      'eth_sepolia': 'Sepolia',
      'bsc': 'BNB Chain',
      'bsc_testnet': 'BSC Testnet',
      'polygon': 'Polygon',
      'arbitrum': 'Arbitrum',
      'optimism': 'Optimism',
      'tron': 'TRON',
      'tron_shasta': 'Shasta',
    };
    return names[chain] ?? chain;
  }

  String get _truncatedHash {
    if (hash.length <= 14) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }

  String? get _explorerUrl {
    const explorers = {
      'eth': 'https://etherscan.io',
      'eth_sepolia': 'https://sepolia.etherscan.io',
      'bsc': 'https://bscscan.com',
      'bsc_testnet': 'https://testnet.bscscan.com',
      'polygon': 'https://polygonscan.com',
      'arbitrum': 'https://arbiscan.io',
      'optimism': 'https://optimistic.etherscan.io',
      'tron': 'https://tronscan.org/#',
      'tron_shasta': 'https://shasta.tronscan.org/#',
    };
    final base = explorers[chain];
    if (base == null) return null;
    return '$base/tx/$hash';
  }

  @override
  Widget build(BuildContext context) {
    final arrowColor = isSentByMe ? Styles.c_0089FF : Colors.green;
    final arrowIcon = isSentByMe ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      constraints: BoxConstraints(maxWidth: 220.w),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(arrowIcon, color: arrowColor, size: 18.w),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _displayText,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Styles.c_0C1C33,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            '$symbol · $_chainLabel',
            style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  _truncatedHash,
                  style: TextStyle(fontSize: 11.sp, color: Styles.c_8E9AB0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_explorerUrl != null)
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse(_explorerUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    '查看',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Styles.c_0089FF,
                      decoration: TextDecoration.underline,
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
