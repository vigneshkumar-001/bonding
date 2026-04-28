import 'package:bonding_app/BondingScreens/Chat/ChatListScreen.dart';
import 'package:bonding_app/BondingScreens/HistoryCard/HistoryCardScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../HomeScreen/ViewModel/UserVM.dart';

class MainBottomBar extends StatefulWidget {
  final int? index;

  const MainBottomBar({super.key, this.index});

  @override
  State<MainBottomBar> createState() => _MainBottomBarState();
}

class _MainBottomBarState extends State<MainBottomBar> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
  }

  /// 🔹 Screens
  List<Widget> get _screens {
    final userId = context.read<UserViewModel>().currentUser?.id ?? "";
    return [
      const HomeScreen(),
      const HistoryCard(),
      UserChatListScreen(backPage: false,  ), // ✅ now valid
      const TransactionsScreen(backPage: false),
      const ProfileScreen(backPage: false),
    ];
  }

  // final List<Widget> _screens = const [
  //
  //   HomeScreen(),
  //   HistoryCard(),4
  //   UserChatListScreen(backPage: false, userId: ''),
  //   TransactionsScreen(backPage: false),
  //   ProfileScreen(backPage: false),
  // ];

  /// 🔹 Back press handler
  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(msg: "Press again to exit");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: _screens[_selectedIndex],

        /// 🔹 Custom Floating Bottom Bar
        bottomNavigationBar: NavigationBar(
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          indicatorColor: Colors.transparent,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: _navIcon(
                "assets/Images/discover.svg",
                colorScheme.onSurfaceVariant,
              ),
              selectedIcon: _selectedNavIcon(
                "assets/Images/discover.svg",
                brand: brand,
              ),
              label: "Home",
            ),
            NavigationDestination(
              icon: _navIcon(
                "assets/Images/history.svg",
                colorScheme.onSurfaceVariant,
              ),
              selectedIcon: _selectedNavIcon(
                "assets/Images/history.svg",
                brand: brand,
              ),
              label: "History",
            ),
            NavigationDestination(
              icon: _navIcon(
                "assets/Images/chat.svg",
                colorScheme.onSurfaceVariant,
              ),
              selectedIcon: _selectedNavIcon(
                "assets/Images/chat.svg",
                brand: brand,
              ),
              label: "Chat",
            ),
            NavigationDestination(
              icon: _navIcon(
                "assets/Images/trans.svg",
                colorScheme.onSurfaceVariant,
              ),
              selectedIcon: _selectedNavIcon(
                "assets/Images/trans.svg",
                brand: brand,
              ),
              label: "Wallet",
            ),
            NavigationDestination(
              icon: _navIcon(
                "assets/Images/profile.svg",
                colorScheme.onSurfaceVariant,
              ),
              selectedIcon: _selectedNavIcon(
                "assets/Images/profile.svg",
                brand: brand,
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Bottom Nav Item
  Widget _navIcon(String svgPath, Color color) {
    return SvgPicture.asset(
      svgPath,
      width: 26,
      height: 26,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _selectedNavIcon(String svgPath, {required BrandTheme brand}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: brand.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SvgPicture.asset(
        svgPath,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
