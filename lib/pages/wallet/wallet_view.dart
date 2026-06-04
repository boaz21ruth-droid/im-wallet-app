import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/wallet/market_service.dart';
import '../../services/wallet/news_service.dart';
import '../../services/wallet/wallet_models.dart';
import 'backup/mnemonic_reveal_view.dart';
import 'change_password_page.dart';
import 'lock/wallet_lock_view.dart';
import 'main/wallet_main_view.dart';
import 'onboarding/wallet_onboard_view.dart';
import 'dapp/dapp_tab.dart';
import 'wallet_logic.dart';

class WalletPage extends StatefulWidget {
  final bool asTab;

  const WalletPage({super.key, this.asTab = false});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final logic = Get.find<WalletLogic>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && logic.newsList.isEmpty) {
        logic.refreshNews();
      }
      if (_tabController.index == 3 && logic.marketList.isEmpty) {
        logic.refreshMarketList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (logic.walletState.value) {
        case WalletState.loading:
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        case WalletState.noWallet:
          return const WalletOnboardView();
        case WalletState.locked:
          return const WalletLockView();
        case WalletState.unlocked:
          return _buildUnlockedScaffold();
      }
    });
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletSettingsSheet(logic: logic),
    );
  }

  Widget _buildUnlockedScaffold() {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_F8F9FA,
        elevation: 0,
        title: Text(
          'Web3 Wallet',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Styles.c_0C1C33,
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.qr_code_scanner, color: Styles.c_0C1C33, size: 22.w),
            onPressed: () {
              // QR scan for receiving
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined,
                color: Styles.c_0C1C33, size: 22.w),
            onPressed: () => _showSettings(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(44.h),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Styles.c_0089FF,
            indicatorWeight: 2.5,
            labelColor: Styles.c_0089FF,
            unselectedLabelColor: Styles.c_8E9AB0,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 14.sp),
            tabs: const [
              Tab(text: '钱包'),
              Tab(text: '资讯'),
              Tab(text: 'DAPP'),
              Tab(text: '行情'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const WalletMainView(),
          _WalletNewsTab(),
          const DAppTab(),
          _WalletMarketTab(),
        ],
      ),
    );
  }
}

// ── News Tab ─────────────────────────────────────────────────────────────────

class _WalletNewsTab extends StatelessWidget {
  final logic = Get.find<WalletLogic>();

  _WalletNewsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilter(),
        Expanded(
          child: Obx(() {
            if (logic.isLoadingNews.value &&
                logic.newsList.isEmpty &&
                logic.hotNewsList.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = logic.newsFilter.value == 0
                ? logic.newsList
                : logic.hotNewsList;
            if (items.isEmpty) {
              return _buildEmpty();
            }
            return RefreshIndicator(
              onRefresh: () => logic.refreshNews(),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Styles.c_E8EAEF,
                  indent: 16.w,
                  endIndent: 16.w,
                ),
                itemBuilder: (_, i) => _NewsArticleCard(post: items[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 48.w, color: Styles.c_8E9AB0),
          SizedBox(height: 12.h),
          Text(
            '暂无资讯',
            style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: logic.refreshNews,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Obx(() => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: Row(
            children: [
              _FilterChip(
                  label: '最新',
                  index: 0,
                  selectedIndex: logic.newsFilter.value,
                  onTap: () => logic.newsFilter.value = 0),
              SizedBox(width: 8.w),
              _FilterChip(
                  label: '热门',
                  index: 1,
                  selectedIndex: logic.newsFilter.value,
                  onTap: () => logic.newsFilter.value = 1),
            ],
          ),
        ));
  }

}

// ── News Article Card ─────────────────────────────────────────────────────────

class _NewsArticleCard extends StatefulWidget {
  final NewsPost post;

  const _NewsArticleCard({required this.post});

  @override
  State<_NewsArticleCard> createState() => _NewsArticleCardState();
}

class _NewsArticleCardState extends State<_NewsArticleCard> {
  String? _translatedTitle;
  bool _isTranslating = false;

  bool get _isChinese => Get.locale?.languageCode == 'zh';
  // Show translate button when app is Chinese and article is from Decrypt (always English).
  bool get _needsTranslate => _isChinese && widget.post.source == 'Decrypt';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_needsTranslate && _translatedTitle != null) {
      _translatedTitle = null;
    }
  }

  Future<void> _translate() async {
    if (_isTranslating) return;
    if (_translatedTitle != null) {
      setState(() => _translatedTitle = null);
      return;
    }
    setState(() => _isTranslating = true);
    final result = await NewsService.translateTitle(widget.post.title);
    if (mounted) {
      setState(() {
        _translatedTitle = result;
        _isTranslating = false;
      });
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _translatedTitle ?? widget.post.title;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final uri = Uri.tryParse(widget.post.url);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Styles.c_0089FF.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.article_outlined,
                  color: Styles.c_0089FF, size: 22.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Styles.c_0C1C33,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Text(
                        widget.post.source,
                        style: TextStyle(
                            fontSize: 11.sp, color: Styles.c_0089FF),
                      ),
                      const Spacer(),
                      Text(
                        _formatRelativeTime(widget.post.publishedAt),
                        style: TextStyle(
                            fontSize: 11.sp, color: Styles.c_8E9AB0),
                      ),
                      if (_needsTranslate) ...[
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: _translate,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 4.h),
                            child: _isTranslating
                                ? SizedBox(
                                    width: 12.w,
                                    height: 12.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Styles.c_8E9AB0,
                                    ),
                                  )
                                : Text(
                                    _translatedTitle != null ? '原' : '译',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: _translatedTitle != null
                                          ? Styles.c_0089FF
                                          : Styles.c_8E9AB0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;

  const _FilterChip({
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

// ── Market Tab ────────────────────────────────────────────────────────────────

class _WalletMarketTab extends StatelessWidget {
  final logic = Get.find<WalletLogic>();

  _WalletMarketTab();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = logic.isLoadingMarket.value;
      final list = logic.marketList;
      if (isLoading && list.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (list.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48.w, color: Styles.c_8E9AB0),
              SizedBox(height: 12.h),
              Text('暂无行情数据',
                  style: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp)),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: logic.refreshMarketList,
                child: const Text('刷新'),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: logic.refreshMarketList,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: list.length,
          itemBuilder: (_, i) => _buildMarketRow(list[i]),
        ),
      );
    });
  }

  Widget _buildMarketRow(CoinMarketData coin) {
    final isPositive = coin.change24h >= 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Styles.c_0089FF.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                coin.symbol.substring(0, coin.symbol.length.clamp(0, 3)),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Styles.c_0089FF,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.symbol,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Styles.c_0C1C33,
                  ),
                ),
                Text(
                  coin.name,
                  style: TextStyle(fontSize: 12.sp, color: Styles.c_8E9AB0),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${_formatPrice(coin.price)}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Styles.c_0C1C33,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${coin.change24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isPositive ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double p) {
    if (p >= 1000) return p.toStringAsFixed(2);
    if (p >= 1) return p.toStringAsFixed(4);
    return p.toStringAsFixed(6);
  }
}


// ── Wallet Settings Sheet ─────────────────────────────────────────────────────

class _WalletSettingsSheet extends StatefulWidget {
  final WalletLogic logic;
  const _WalletSettingsSheet({required this.logic});

  @override
  State<_WalletSettingsSheet> createState() => _WalletSettingsSheetState();
}

class _WalletSettingsSheetState extends State<_WalletSettingsSheet> {
  WalletLogic get logic => widget.logic;

  static const _lockOptions = [
    (label: '1 分钟', seconds: 60),
    (label: '5 分钟', seconds: 300),
    (label: '15 分钟', seconds: 900),
    (label: '1 小时', seconds: 3600),
    (label: '永不锁定', seconds: 0),
  ];

  Future<void> _toggleBiometric() async {
    final enabled = logic.settings.value.biometricEnabled;
    if (enabled) {
      final err = await logic.toggleBiometricEnabled('');
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    final pwdCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('开启生物识别'),
        content: TextField(
          controller: pwdCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入当前密码'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      pwdCtrl.dispose();
      return;
    }
    final err = await logic.toggleBiometricEnabled(pwdCtrl.text);
    pwdCtrl.dispose();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Styles.c_FFFFFF,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                SizedBox(height: 20.h),
                Text(
                  '钱包设置',
                  style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Styles.c_0C1C33),
                ),
                SizedBox(height: 20.h),
                Text(
                  '自动锁定时间',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: Styles.c_8E9AB0,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10.h),
                Obx(() {
                  final current = logic.settings.value.autoLockSeconds;
                  return Column(
                    children: _lockOptions.map((opt) {
                      final isSelected = current == opt.seconds;
                      return GestureDetector(
                        onTap: () {
                          logic.setAutoLockSeconds(opt.seconds);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Styles.c_0089FF.withAlpha(20)
                                : Styles.c_F8F9FA,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? Styles.c_0089FF
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: isSelected
                                      ? Styles.c_0089FF
                                      : Styles.c_0C1C33,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(Icons.check_circle,
                                    color: Styles.c_0089FF, size: 20.w),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 20.h),
                Text(
                  '安全',
                  style: TextStyle(
                      fontSize: 13.sp,
                      color: Styles.c_8E9AB0,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 10.h),
                Obx(() {
                  final enabled = logic.settings.value.biometricEnabled;
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Styles.c_F8F9FA,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fingerprint,
                            color: Styles.c_0C1C33, size: 20.w),
                        SizedBox(width: 10.w),
                        Text(
                          '生物识别解锁',
                          style: TextStyle(
                              fontSize: 15.sp, color: Styles.c_0C1C33),
                        ),
                        const Spacer(),
                        Switch(
                          value: enabled,
                          activeThumbColor: Styles.c_0089FF,
                          onChanged: (_) => _toggleBiometric(),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Get.to(() => const ChangePasswordPage());
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: Styles.c_F8F9FA,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset,
                            color: Styles.c_0C1C33, size: 20.w),
                        SizedBox(width: 10.w),
                        Text(
                          '修改密码',
                          style: TextStyle(
                              fontSize: 15.sp, color: Styles.c_0C1C33),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color: Styles.c_8E9AB0, size: 20.w),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // close sheet
                    Get.to(() => const MnemonicRevealPage());
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF8FF),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFBAE2FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: Color(0xFF005BB3), size: 20),
                        SizedBox(width: 10.w),
                        Text(
                          '备份助记词',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF005BB3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color: const Color(0xFF005BB3).withOpacity(0.6),
                            size: 20.w),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: () => _confirmDeleteLocalWallet(context),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            color: Color(0xFFB42318), size: 20),
                        SizedBox(width: 10.w),
                        Text(
                          '删除本机钱包',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFFB42318),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteLocalWallet(BuildContext context) async {
    // Use the dialog's own context for pop, not the outer sheet context —
    // the outer context's pop pops the topmost (the dialog) but the intent
    // is clearer and less brittle this way.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('删除本机钱包？'),
        content: const Text('只会清除当前设备保存的助记词和钱包数据，不会删除账号或链上资产。删除前请确认已备份助记词。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('删除',
                style: TextStyle(color: Color(0xFFB42318))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    // Close the bottom sheet first so the success/onboarding view is visible.
    Navigator.pop(context);

    EasyLoading.show(status: '正在删除...');
    try {
      await logic.deleteLocalWallet();
      EasyLoading.dismiss();
      IMViews.showToast('已删除本机钱包');
    } catch (e, st) {
      EasyLoading.dismiss();
      debugPrint('deleteLocalWallet failed: $e\n$st');
      EasyLoading.showError('删除失败：$e');
    }
  }
}
