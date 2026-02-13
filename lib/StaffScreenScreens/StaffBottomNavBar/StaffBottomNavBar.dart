import 'package:bonding_app/BondingScreens/Chat/ChatListScreen.dart';
import 'package:bonding_app/BondingScreens/HistoryCard/HistoryCardScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/StaffScreenScreens/RecentCallScreen/RecentCallScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/DashBoardScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffProfileScreen/staffProfileScreen.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/staffChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';


class StaffBottomBar extends StatefulWidget {
  final int? index;

  const StaffBottomBar({super.key, this.index});

  @override
  State<StaffBottomBar> createState() => _StaffBottomBarState();
}

class _StaffBottomBarState extends State<StaffBottomBar> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
  }

  /// 🔹 Screens
  final List<Widget> _screens = [
    const BondingDashboardPage(),
    const RecentCallsPage(backPage: false,),
    StaffChatListScreen(backPage: false,),
    const WithdrawHistory(backPage: false,),
    const StaffProfileScreen(backPage: false,),
  ];

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
          decoration: BoxDecoration(
            color: const Color(0xFF282323),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(14),topRight: Radius.circular(14)),

          ),
          child: SafeArea(
            child: Container(
              height: 60,

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem("assets/Images/discover.svg", 0),
                  _navItem("assets/Images/history.svg", 1),
                  _navItem("assets/Images/chat.svg", 2),
                  _navItem("assets/Images/trans.svg", 3),
                  _navItem("assets/Images/profile.svg", 4),

                ],
              ),
            ),
          ),
        ),

      ),
    );
  }

  /// 🔹 Bottom Nav Item
  Widget _navItem(String svgPath, int index) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? const LinearGradient(
            colors: [
              Color(0xFFB86AF6),
              Color(0xFFFF6A6A),
            ],
          )
              : null,
        ),
        child: Center(
          child: SvgPicture.asset(
            svgPath,
            width: 28,
            height: 28,
            colorFilter: ColorFilter.mode(
              isActive ? Colors.white : Color(0XFFbebdbd),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }


}
