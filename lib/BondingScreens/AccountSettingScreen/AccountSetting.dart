import 'package:bonding_app/BondingScreens/BlockedUsers/BlockUserScreen.dart';
import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/DeleteAccountScreen.dart';
import 'package:bonding_app/BondingScreens/ReportOverview/ReportOverviewScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF100a0a),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        bondNavigator.backPage(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF35272d),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppText(
                      "account settings",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: "privacy policy",
                        onTap: () {
                          // Navigate to privacy policy
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.block_outlined,
                        title: "Blocked users",
                        onTap: () {
                          bondNavigator.newPage(context, page: BlockedUsersScreen());
                          // Navigate to blocked users
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.report_outlined,
                        title: "Report overview",
                        onTap: () {
                          bondNavigator.newPage(context, page: ReportOverviewScreen());
                          // Navigate to report overview
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.delete_outline,
                        title: "Delete Account",

                        onTap: () {
                          bondNavigator.newPage(context, page: DeleteAccountScreen());
                          // Handle delete account
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF231d1d),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.grey[400],
              size: 28,
            ),
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