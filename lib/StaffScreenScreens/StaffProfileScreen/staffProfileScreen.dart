import 'package:bonding_app/BondingScreens/AccountSettingScreen/AccountSetting.dart';
// ← staff wallet
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart'; // can keep or make staff version
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/WalletFlow/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class StaffProfileScreen extends StatefulWidget {
  final bool backPage;
  const StaffProfileScreen({super.key, required this.backPage});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, staffVM, child) {
        final staff = staffVM.currentStaff;

        // Loading / error states
        if (staffVM.isFetchingSingleStaff) {
          return const Scaffold(
            backgroundColor: Color(0xFF100a0a),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (staff == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF100a0a),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No staff profile data available", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: staffVM.fetchStaffSingleData,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF100a0a),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF100a0a),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top bar: Back + Title + Edit
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        widget.backPage?  GestureDetector(
                            onTap: () => bondNavigator.backPage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF35272d),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                          ):GestureDetector(
                          onTap: () => bondNavigator.newPageRemoveUntil(context, page: StaffBottomBar(index: 0,)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF35272d),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.arrow_back, color: Colors.white),
                            ),
                          ),
                        ),
                          AppText(
                            "Profile",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                      SizedBox(width: 20,)
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Picture (using staff.image)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFcc529f), width: 3),
                      ),
                      child: ClipOval(
                        child: staff.image != null && staff.image!.isNotEmpty
                            ? Image.network(
                          staff.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            "assets/Images/profileimg.png",
                            fit: BoxFit.cover,
                          ),
                        )
                            : Image.asset("assets/Images/profileimg.png", fit: BoxFit.cover),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Staff Name
                    Text(
                      staff.name ?? "Staff",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Staff ID
                    Text(
                      "ID: ${staff.memberID}",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Menu Items
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF231d1d),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildMenuRow(
                              svg: "assets/Images/walleticon.svg",
                              title: "Wallet",
                              onTap: () {
                                bondNavigator.newPage(context, page: const StaffWalletScreen());
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/helpicon.svg",
                              title: "Help & support",
                              onTap: () {
                                // TODO: Navigate to staff help/support screen
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/supporticon.svg",
                              title: "Withdraw History",
                              onTap: () {
                                bondNavigator.newPage(context, page: const WithdrawHistory(backPage: true,)); // or staff-specific
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/accounticon.svg",
                              title: "Account settings",
                              onTap: () {
                                bondNavigator.newPage(context, page: const AccountSettingsScreen());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF231d1d),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildMenuRow(
                          svg: "assets/Images/logouticon.svg",
                          title: "Logout",
                          titleColor: const Color(0xFFFF083D),
                          onTap: () {
                            // TODO: Staff logout logic (clear token, navigate to login)
                            Utils.snackBar("Logged out successfully");
                            // bondNavigator.replaceAll(context, page: const LoginScreen());
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Support text
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                              children: [
                                TextSpan(text: "Need Help? please contact "),
                                TextSpan(
                                  text: "support@bonding.com",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuRow({
    required String svg,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(svg),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}