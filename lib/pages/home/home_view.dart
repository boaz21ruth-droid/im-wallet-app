import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../contacts/contacts_view.dart';
import '../conversation/conversation_view.dart';
import '../wallet/wallet_view.dart';
import '../mine/mine_view.dart';
import 'home_logic.dart';

class HomePage extends StatelessWidget {
  final logic = Get.find<HomeLogic>();

  HomePage({super.key});

  List<PersistentTabConfig> _tabs() => [
        PersistentTabConfig(
          screen: ConversationPage(),
          item: ItemConfig(
            icon: _setupIcon(
              const Icon(Icons.chat_bubble, size: 24),
              logic.unreadMsgCount.value,
            ),
            inactiveIcon: _setupIcon(
              const Icon(Icons.chat_bubble_outline, size: 24),
              logic.unreadMsgCount.value,
            ),
            title: StrRes.home,
            activeForegroundColor: Styles.c_0089FF,
            inactiveForegroundColor: Styles.c_8E9AB0,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: ContactsPage(),
          item: ItemConfig(
            icon: _setupIcon(
              const Icon(Icons.people, size: 24),
              logic.unhandledCount.value,
            ),
            inactiveIcon: _setupIcon(
              const Icon(Icons.people_outline, size: 24),
              logic.unhandledCount.value,
            ),
            title: StrRes.contacts,
            activeForegroundColor: Styles.c_0089FF,
            inactiveForegroundColor: Styles.c_8E9AB0,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: const WalletPage(asTab: true),
          item: ItemConfig(
            icon: const Icon(Icons.account_balance_wallet, size: 24),
            inactiveIcon: const Icon(Icons.account_balance_wallet_outlined, size: 24),
            title: StrRes.wallet,
            activeForegroundColor: Styles.c_0089FF,
            inactiveForegroundColor: Styles.c_8E9AB0,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: MinePage(),
          item: ItemConfig(
            icon: const Icon(Icons.person, size: 24),
            inactiveIcon: const Icon(Icons.person_outline, size: 24),
            title: StrRes.mine,
            activeForegroundColor: Styles.c_0089FF,
            inactiveForegroundColor: Styles.c_8E9AB0,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
      ];

  Widget _setupIcon(Widget icon, int unReadCount) {
    return Stack(
      alignment: Alignment.center,
      children: [
        icon,
        Positioned(
          top: 0,
          right: 0,
          child: Transform.translate(
            offset: const Offset(2, -2),
            child: UnreadCountView(count: unReadCount),
          ),
        ),
      ],
    );
  }

  Widget _buildNavBar(NavBarConfig navBarConfig) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      height: navBarConfig.navBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navBarConfig.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = navBarConfig.selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => navBarConfig.onItemSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Styles.c_0089FF.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: IconTheme(
                      data: IconThemeData(
                        size: item.iconSize,
                        color: isSelected
                            ? item.activeForegroundColor
                            : item.inactiveForegroundColor,
                      ),
                      child: isSelected ? item.icon : item.inactiveIcon,
                    ),
                  ),
                  4.verticalSpace,
                  if (item.title != null)
                    Text(
                      item.title!,
                      style: item.textStyle.copyWith(
                        color: isSelected
                            ? item.activeForegroundColor
                            : item.inactiveForegroundColor,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_FFFFFF,
      body: Obx(
        () => PersistentTabView(
          tabs: _tabs(),
          navBarBuilder: _buildNavBar,
          navBarOverlap: const NavBarOverlap.none(),
          screenTransitionAnimation: const ScreenTransitionAnimation.none(),
        ),
      ),
    );
  }
}
