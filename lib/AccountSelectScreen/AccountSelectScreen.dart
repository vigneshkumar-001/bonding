import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/LoginScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountSelectScreen extends StatefulWidget {
  const AccountSelectScreen({super.key});

  @override
  State<AccountSelectScreen> createState() => _AccountSelectScreenState();
}

class _AccountSelectScreenState extends State<AccountSelectScreen> {
  // 0 = none, 1 = User, 2 = Staff
  int selectedAccount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF5A1F3F),
              Color(0xFF3A152A),
              Color(0xFF140810),
              Color(0xFF140810),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    "assets/Images/bonding.svg",
                    height: 40,

                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                "Choose account type",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 50),

              // Account Type Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // User Card
                  _buildAccountCard(
                    imagePath: "assets/Images/user.png", // Replace with your actual asset
                    label: "User",
                    isSelected: selectedAccount == 1,
                    onTap: () {
                      setState(() {
                        selectedAccount = 1;
                      });
                    },
                  ),

                  const SizedBox(width: 30),

                  // Staff Card
                  _buildAccountCard(
                    imagePath: "assets/Images/staff.png", // Replace with your actual asset
                    label: "Staff",
                    isSelected: selectedAccount == 2,
                    onTap: () {
                      setState(() {
                        selectedAccount = 2;
                      });
                    },
                  ),
                ],
              ),

              const Spacer(),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: GestureDetector(
                  onTap: selectedAccount == 0
                      ? null // Disabled if nothing selected
                      : () {
                    if (selectedAccount == 1) {
                      // Navigate to User page
                      bondNavigator.newPage(context, page: const LoginScreen());
                    } else if (selectedAccount == 2) {
                      // Navigate to Staff page - CHANGE THIS TO YOUR STAFF PAGE
                      bondNavigator.newPage(context, page: const StaffRegisterScreen()); // Example
                    }
                  },
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: selectedAccount == 0
                          ? const LinearGradient(
                        colors: [Color(0xFF666666), Color(0xFF888888)],
                      )
                          : const LinearGradient(
                        colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Continue  →",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required String imagePath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  })
  {
    return GestureDetector(
      onTap: onTap,
      child: Container(


        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0XFFf56464) : Color(0XFF5f3550),
            width: 1,
          ),

        ),
        child:Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Image.asset(imagePath,height: 120,),
              AppText(label)
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for Staff Home Screen - replace with your actual staff page
