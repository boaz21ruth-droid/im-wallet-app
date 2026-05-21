import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../calls/calls_view.dart';
import '../contacts/contacts_view.dart';
import '../conversation/conversation_view.dart';
import '../mine/favorites/favorites_view.dart';
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
              const Icon(Icons.chat_bubble, size: 22),
              logic.unreadMsgCount.value,
            ),
            inactiveIcon: _setupIcon(
              const Icon(Icons.chat_bubble_outline, size: 22),
              logic.unreadMsgCount.value,
            ),
            title: StrRes.home,
            activeForegroundColor: Colors.white,
            inactiveForegroundColor: Styles.c_8E9AB0,
            activeColorSecondary: Styles.c_0089FF,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: CallsPage(),
          item: ItemConfig(
            icon: const Icon(Icons.call, size: 22),
            inactiveIcon: const Icon(Icons.call_outlined, size: 22),
            title: '通话',
            activeForegroundColor: Colors.white,
            inactiveForegroundColor: Styles.c_8E9AB0,
            activeColorSecondary: Styles.c_0089FF,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: ContactsPage(),
          item: ItemConfig(
            icon: _setupIcon(
              const Icon(Icons.people, size: 22),
              logic.unhandledCount.value,
            ),
            inactiveIcon: _setupIcon(
              const Icon(Icons.people_outline, size: 22),
              logic.unhandledCount.value,
            ),
            title: StrRes.contacts,
            activeForegroundColor: Colors.white,
            inactiveForegroundColor: Styles.c_8E9AB0,
            activeColorSecondary: Styles.c_0089FF,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: FavoritesPage(asTab: true),
          item: ItemConfig(
            icon: const Icon(Icons.bookmark, size: 22),
            inactiveIcon: const Icon(Icons.bookmark_border, size: 22),
            title: '收藏',
            activeForegroundColor: Colors.white,
            inactiveForegroundColor: Styles.c_8E9AB0,
            activeColorSecondary: Styles.c_0089FF,
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        PersistentTabConfig(
          screen: MinePage(),
          item: ItemConfig(
            icon: const Icon(Icons.person, size: 22),
            inactiveIcon: const Icon(Icons.person_outline, size: 22),
            title: StrRes.mine,
            activeForegroundColor: Colors.white,
            inactiveForegroundColor: Styles.c_8E9AB0,
            activeColorSecondary: Styles.c_0089FF,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_FFFFFF,
      body: Obx(
        () => PersistentTabView(
          tabs: _tabs(),
          navBarBuilder: (navBarConfig) => Style8BottomNavBar(
            navBarConfig: navBarConfig,
            navBarDecoration: NavBarDecoration(
              color: Styles.c_FFFFFF,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
          ),
          navBarOverlap: const NavBarOverlap.none(),
          screenTransitionAnimation: const ScreenTransitionAnimation.none(),
        ),
      ),
    );
  }
}
