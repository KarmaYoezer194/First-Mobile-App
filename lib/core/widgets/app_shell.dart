import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cart/screens/cart_screen.dart';
import '../../features/cart/widgets/cart_icon_anchor.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/search/search_page.dart';
import '../../providers/cart_provider.dart';
import '../../providers/nav_provider.dart';
import 'go_buy_bottom_nav.dart';

/// Hosts the 4-tab bottom navigation: Home, Search, Cart, Profile.
/// Alerts (Home's bell) and Settings (Profile's gear) are pushed routes.
///
/// Uses [IndexedStack] so each tab keeps its scroll position and state
/// when switching away and back.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _pages = [
    HomePage(),
    SearchPage(),
    CartScreen(),
    ProfilePage(),
  ];

  /// The Cart tab icon is the fly-to-cart target while the tabs are on
  /// screen.
  final GlobalKey _cartTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    CartIconAnchor.register(_cartTabKey);
  }

  @override
  void dispose() {
    CartIconAnchor.unregister(_cartTabKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bottomNavIndexProvider);
    final cartCount = ref.watch(cartProvider.select((s) => s.totalQuantity));

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: GoBuyBottomNav(
        currentIndex: index,
        onTap: (i) => ref.read(bottomNavIndexProvider.notifier).state = i,
        items: [
          const GoBuyNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const GoBuyNavItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search_rounded,
            label: 'Search',
          ),
          GoBuyNavItem(
            key: _cartTabKey,
            icon: Icons.shopping_bag_outlined,
            activeIcon: Icons.shopping_bag_rounded,
            label: 'Cart',
            badgeCount: cartCount,
          ),
          const GoBuyNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
