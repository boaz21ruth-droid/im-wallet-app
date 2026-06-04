import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../wallet_logic.dart';

// ── Data ──────────────────────────────────────────────────────────────────────

class _DAppItem {
  final String name;
  final String description;
  final String url;
  final String iconUrl;
  final String category; // 'DeFi' | 'NFT' | '工具'
  final List<String> chains; // empty = all chains

  const _DAppItem({
    required this.name,
    required this.description,
    required this.url,
    required this.iconUrl,
    required this.category,
    this.chains = const [],
  });
}

const _kDApps = [
  // DeFi
  _DAppItem(
    name: 'Uniswap',
    description: '去中心化交易所',
    url: 'https://app.uniswap.org',
    iconUrl: 'https://app.uniswap.org/favicon.ico',
    category: 'DeFi',
    chains: ['eth', 'polygon', 'arbitrum', 'optimism'],
  ),
  _DAppItem(
    name: 'PancakeSwap',
    description: 'BNB Chain 头部 DEX',
    url: 'https://pancakeswap.finance',
    iconUrl: 'https://pancakeswap.finance/favicon.ico',
    category: 'DeFi',
    chains: ['bsc'],
  ),
  _DAppItem(
    name: 'Curve',
    description: '稳定币兑换协议',
    url: 'https://curve.fi',
    iconUrl: 'https://curve.fi/favicon.ico',
    category: 'DeFi',
    chains: ['eth', 'polygon', 'arbitrum'],
  ),
  _DAppItem(
    name: 'Aave',
    description: '去中心化借贷协议',
    url: 'https://app.aave.com',
    iconUrl: 'https://app.aave.com/favicon.ico',
    category: 'DeFi',
    chains: ['eth', 'polygon', 'arbitrum', 'optimism'],
  ),
  _DAppItem(
    name: '1inch',
    description: 'DEX 聚合交易',
    url: 'https://app.1inch.io',
    iconUrl: 'https://app.1inch.io/favicon.ico',
    category: 'DeFi',
    chains: ['eth', 'bsc', 'polygon', 'arbitrum', 'optimism'],
  ),
  // NFT
  _DAppItem(
    name: 'OpenSea',
    description: '全球最大 NFT 市场',
    url: 'https://opensea.io',
    iconUrl: 'https://opensea.io/favicon.ico',
    category: 'NFT',
    chains: ['eth', 'polygon'],
  ),
  _DAppItem(
    name: 'Blur',
    description: '专业 NFT 交易平台',
    url: 'https://blur.io',
    iconUrl: 'https://blur.io/favicon.ico',
    category: 'NFT',
    chains: ['eth'],
  ),
  // 工具
  _DAppItem(
    name: 'Etherscan',
    description: '以太坊区块浏览器',
    url: 'https://etherscan.io',
    iconUrl: 'https://etherscan.io/favicon.ico',
    category: '工具',
    chains: ['eth'],
  ),
  _DAppItem(
    name: 'BscScan',
    description: 'BNB Chain 区块浏览器',
    url: 'https://bscscan.com',
    iconUrl: 'https://bscscan.com/favicon.ico',
    category: '工具',
    chains: ['bsc'],
  ),
  _DAppItem(
    name: 'Snapshot',
    description: '链上治理投票',
    url: 'https://snapshot.org',
    iconUrl: 'https://snapshot.org/favicon.ico',
    category: '工具',
  ),
  _DAppItem(
    name: 'DeBank',
    description: 'DeFi 资产追踪',
    url: 'https://debank.com',
    iconUrl: 'https://debank.com/favicon.ico',
    category: '工具',
  ),
];

// ── Tab ───────────────────────────────────────────────────────────────────────

class DAppTab extends StatefulWidget {
  const DAppTab({super.key});

  @override
  State<DAppTab> createState() => _DAppTabState();
}

class _DAppTabState extends State<DAppTab> {
  static const _categories = ['全部', 'DeFi', 'NFT', '工具'];
  int _selectedCategory = 0;

  List<_DAppItem> _filtered(String chainKey) => _kDApps.where((d) {
        final chainOk = d.chains.isEmpty || d.chains.contains(chainKey);
        final catOk = _selectedCategory == 0 ||
            d.category == _categories[_selectedCategory];
        return chainOk && catOk;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<WalletLogic>();
    return Column(
      children: [
        _buildFilter(),
        Expanded(
          child: Obx(() {
            final items = _filtered(logic.selectedChainKey.value);
            if (items.isEmpty) return _buildEmpty();
            return GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 0.88,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _DAppCard(item: items[i]),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_categories.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                  right: i < _categories.length - 1 ? 8.w : 0),
              child: _DAppFilterChip(
                label: _categories[i],
                index: i,
                selectedIndex: _selectedCategory,
                onTap: () => setState(() => _selectedCategory = i),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_off_outlined, size: 48.w, color: Styles.c_8E9AB0),
          SizedBox(height: 12.h),
          Text(
            '暂无匹配的 DApp',
            style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _DAppCard extends StatelessWidget {
  final _DAppItem item;

  const _DAppCard({required this.item});

  Future<void> _launch() async {
    final uri = Uri.tryParse(item.url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DAppIcon(url: item.iconUrl),
                const Spacer(),
                _CategoryBadge(category: item.category),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Styles.c_0C1C33,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Text(
                item.description,
                style: TextStyle(fontSize: 11.sp, color: Styles.c_8E9AB0),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon ──────────────────────────────────────────────────────────────────────

class _DAppIcon extends StatelessWidget {
  final String url;

  const _DAppIcon({required this.url});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: Styles.c_0089FF.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(Icons.language, color: Styles.c_0089FF, size: 22.w),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: ImageUtil.networkImage(
        url: url,
        width: 40.w,
        height: 40.w,
        fit: BoxFit.cover,
        loadProgress: false,
        errorWidget: fallback,
      ),
    );
  }
}

// ── Category Badge ────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  Color get _color {
    switch (category) {
      case 'DeFi':
        return Styles.c_0089FF;
      case 'NFT':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10.sp,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _DAppFilterChip extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const _DAppFilterChip({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Styles.c_0089FF : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Styles.c_0089FF : Styles.c_E8EAEF,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: isSelected ? Colors.white : Styles.c_8E9AB0,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
