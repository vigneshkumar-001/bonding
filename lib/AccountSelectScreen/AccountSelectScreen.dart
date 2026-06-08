import 'package:bonding_app/BondingScreens/LoginScreens/LoginScreen.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:flutter/material.dart';

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
        decoration: const BoxDecoration(gradient: Apptheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    "assets/Images/appLogo.png",
                    height: 40,
                    fit: BoxFit.contain,
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final useCompactCards = constraints.maxWidth < 390;
                  final cardHeight = useCompactCards ? 90.0 : 112.0;
                  final cardSpacing = useCompactCards ? 14.0 : 18.0;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildAccountCard(
                          height: cardHeight,
                          imagePath: "assets/Images/men.png",
                          label: "Men",
                          isCompact: useCompactCards,
                          isSelected: selectedAccount == 1,
                          onTap: () {
                            setState(() {
                              selectedAccount = 1;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildAccountCard(
                          height: cardHeight,
                          imagePath: "assets/Images/women.png",
                          label: "Women",
                          isCompact: useCompactCards,
                          isSelected: selectedAccount == 2,
                          onTap: () {
                            setState(() {
                              selectedAccount = 2;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const Spacer(),

              // Continue Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                child: GestureDetector(
                  onTap: selectedAccount == 0
                      ? null // Disabled if nothing selected
                      : () {
                          if (selectedAccount == 1) {
                            // Navigate to User page
                            bondNavigator.newPage(
                              context,
                              page: const LoginScreen(),
                            );
                          } else if (selectedAccount == 2) {
                            // Navigate to Staff page - CHANGE THIS TO YOUR STAFF PAGE
                            bondNavigator.newPage(
                              context,
                              page: const StaffRegisterScreen(
                                mode: StaffAuthMode.login,
                              ),
                            ); // Example
                          }
                        },
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: selectedAccount == 0
                          ? Apptheme.buttonDisabledGradient
                          : Apptheme.buttonGradient,
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
    required double height,
    required bool isCompact,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 15,
          vertical: isCompact ? 14 : 20,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? Apptheme.surface2 : Apptheme.surface,
          border: Border.all(
            color: isSelected ? Apptheme.buttonGradientEnd : Apptheme.outline,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Apptheme.buttonGradientEnd.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.03),
                      Colors.white.withOpacity(0.01),
                    ],
                  )
                : null,
          ),
          child: Column(
            children: [
              Image.asset(imagePath, height: height),
              SizedBox(height: isCompact ? 6 : 7),
              AppText(
                label,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isCompact ? 14 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for Staff Home Screen - replace with your actual staff page
