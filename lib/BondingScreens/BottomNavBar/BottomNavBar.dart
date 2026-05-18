import 'package:bonding_app/BondingScreens/Chat/ChatListScreen.dart';
import 'package:bonding_app/BondingScreens/HistoryCard/HistoryCardScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return [
      const HomeScreen(),
      const HistoryCard(),
      UserChatListScreen(backPage: false), // ✅ now valid
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_selectedIndex],

        /// 🔹 Custom Floating Bottom Bar
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141018),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem("assets/Images/discover.svg", "Home", 0),
                  _navItem("assets/Images/history.svg", "History", 1),
                  _navItem("assets/Images/chat.svg", "Chat", 2),
                  _navItem("assets/Images/trans.svg", "Wallet", 3),
                  _navItem("assets/Images/profile.svg", "Profile", 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Bottom Nav Item
  Widget _navItem(String svgPath, String label, int index) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive ? Apptheme.buttonGradient : null,
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    isActive ? Colors.white : const Color(0xFF8B8B8B),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF8B8B8B),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
