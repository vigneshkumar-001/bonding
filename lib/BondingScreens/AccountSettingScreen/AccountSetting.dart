import 'package:bonding_app/BondingScreens/BlockedUsers/BlockUserScreen.dart';
import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/DeleteAccountScreen.dart';
import 'package:bonding_app/BondingScreens/PrivacyPolicy/privacy_policy_screen.dart';
import 'package:bonding_app/BondingScreens/ReportOverview/ReportOverviewScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';

import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';
import '../../Reusable_Widgets/under_development_widgets.dart';

class AccountSettingsScreen extends StatefulWidget {
  final bool isStaff;
  final String userId;
  const AccountSettingsScreen({
    super.key,
    required this.isStaff,
    required this.userId,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: const CommonAppBar(
        title: 'Account Settings',
        usePaddedLeading: true,
        bg: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: ListView(
          children: [
            _buildSettingsItem(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: "Privacy policy",
              onTap: () {
                bondNavigator.newPage(context, page: const PrivacyPolicyScreen());
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.block_outlined,
              title: "Blocked users",
              onTap: () {
                bondNavigator.newPage(
                  context,
                  page: BlockedUsersScreen(
                    isStaff: widget.isStaff,
                    userId: widget.userId,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.report_outlined,
              title: "Report overview",
              onTap: () {
                UnderDevelopmentWidgets.buildUnderDevelopmentDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context: context,
              icon: Icons.delete_outline,
              title: "Delete account",
              iconColor: cs.error,
              titleColor: cs.error,
              onTap: () {
                bondNavigator.newPage(
                  context,
                  page: DeleteAccountScreen(isStaff: widget.isStaff),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? cs.onSurfaceVariant, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? cs.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: cs.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
