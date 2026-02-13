import 'package:bonding_app/BondingScreens/AccountSettingScreen/AccountSetting.dart';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/EditProfile/EditProfileScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final bool backPage;
  const ProfileScreen({super.key, required this.backPage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Listen to UserViewModel for real-time user data
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final user = userVM.currentUser;

        // If still loading or no user, show loading or fallback
        if (userVM.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (user == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No user data available", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: userVM.fetchUserDetails,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
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
                         widget.backPage? GestureDetector(
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
                           onTap: () => bondNavigator.newPageRemoveUntil(context, page: MainBottomBar(index: 0,)),
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
                          GestureDetector(
                            onTap: () {
                              bondNavigator.newPage(context, page: const EditProfileScreen());
                            },
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Picture (dynamic from API)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFcc529f), width: 3),
                      ),
                      child: ClipOval(
                        child: user.image != null && user.image!.isNotEmpty
                            ? Image.network(
                          user.image!,
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

                    // Username (dynamic)
                    Text(
                      user.name ?? "User",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // User ID (dynamic)
                    Text(
                      "ID: ${user.memberID}",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Menu Items Container
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
                                bondNavigator.newPage(context, page: const WalletScreen());
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/helpicon.svg",
                              title: "Help & support",
                              onTap: () {
                                // TODO: Navigate to help screen
                              },
                            ),
                            _buildMenuRow(
                              svg: "assets/Images/supporticon.svg",
                              title: "Transactions",
                              onTap: () {
                                bondNavigator.newPage(context, page: const TransactionsScreen(backPage: true,));
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

                    // Logout Container
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
                            // TODO: Handle logout (clear token, navigate to login)
                            Utils.snackBar("Logged out successfully");
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Support Text
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