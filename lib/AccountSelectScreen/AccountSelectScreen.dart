import 'package:bonding_app/BondingScreens/LoginScreens/LoginScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';

class AccountSelectScreen extends StatefulWidget {
  const AccountSelectScreen({super.key});

  @override
  State<AccountSelectScreen> createState() => _AccountSelectScreenState();
}

class _AccountSelectScreenState extends State<AccountSelectScreen> {
  // 0 = none, 1 = Men, 2 = Women
  int selectedAccount = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = BrandTheme.of(context);

    return AppScaffold(
      body: Column(
        children: [
              const SizedBox(height: 20),

              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    "assets/Images/bonding.png",
                    height: 40,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                "Choose account type",
                style: TextStyle(
                  color: cs.onSurface,
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
                    context: context,
                    height: 120,
                    imagePath: "assets/Images/men.png",
                    label: "Men",
                    isSelected: selectedAccount == 1,
                    onTap: () {
                      setState(() {
                        selectedAccount = 1;
                      });
                    },
                  ),

                  const SizedBox(width: 30),

                  // Women Card
                  _buildAccountCard(
                    context: context,
                    height: 120,
                    imagePath: "assets/Images/women.png",
                    label: "Women",
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
                            // Navigate to Women (provider) page
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
                      borderRadius: BorderRadius.circular(12),
                      gradient: selectedAccount == 0
                          ? LinearGradient(
                              colors: [
                                cs.surfaceContainerHighest.withValues(alpha: 0.6),
                                cs.surfaceContainerHighest.withValues(alpha: 0.35),
                              ],
                            )
                          : brand.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        "Continue →",
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
    );
  }

  Widget _buildAccountCard({
    required BuildContext context,
    required String imagePath,
    required String label,
    required double height,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: height),
            const SizedBox(height: 7),
            AppText(label, color: cs.onSurface),
          ],
        ),
      ),
    );
  }
}

// Placeholder for Women home screen - replace with your actual page

