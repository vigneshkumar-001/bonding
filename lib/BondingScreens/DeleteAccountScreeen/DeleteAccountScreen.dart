import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/DeleteReasonScreen.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart'; // If you use AppText
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart'; // For navigation
import 'package:bonding_app/Reusable_Widgets/Common_AppBar/common_app_bar.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_scaffold.dart';

class DeleteAccountScreen extends StatelessWidget {
  final bool isStaff;
  const DeleteAccountScreen({super.key, required this.isStaff});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = BrandTheme.of(context);

    return AppScaffold(
      appBar: const CommonAppBar(
        title: "Delete Account",
        usePaddedLeading: true,
        bg: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure want to delete account ?",
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),

            // First bullet point
            _buildBulletPoint(
              context,
              "Information related to your account will be kept for 30 days\nand will be completely purged after no activity for continuous 30 days.",
            ),
            const SizedBox(height: 24),

            // Second bullet point
            _buildBulletPoint(
              context,
              "After the account is deleted, you will no longer be able to log in or use the account, and the account cannot be recovered.",
            ),

            const Spacer(),

            // Continue Button
            GestureDetector(
              onTap: () {
                bondNavigator.newPage(
                  context,
                  page: DeleteReasonScreen(isStaff: isStaff),
                );
              },
              child: Container(
                height: 45,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: brand.primaryGradient,
                ),
                alignment: Alignment.center,
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Go back button
            GestureDetector(
              onTap: () {
                bondNavigator.backPage(context);
              },
              child: Container(
                height: 45,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return brand.primaryGradient.createShader(bounds);
                  },
                  child: AppText(
                    "Go back",

                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // Important: Use white as base color so gradient applies properly
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
