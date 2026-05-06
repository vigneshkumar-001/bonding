import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffSelectInterestScreen/StaffSelectInterestScreen.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';

class ApprovedScreen extends StatefulWidget {
  const ApprovedScreen({super.key});

  @override
  State<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends State<ApprovedScreen> {
  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      resizeToAvoidBottomInset: true,
      safeArea: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Image.asset("assets/Images/bonding.png", height: 35),
            const SizedBox(height: 30),
            Center(
              child: Image.asset("assets/Images/tick.png", height: 200),
            ),
            const SizedBox(height: 20),
            Center(
              child: AppText(
                "Congratulations Your\nProfile is Approved",
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: AppText(
                "Your identity and documents have been successfully verified. You are now an approved partner and can start receiving calls and earning.",
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
                maxLines: 5,
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GestureDetector(
            onTap: () {
              bondNavigator.newPage(context, page: const StaffInterestScreen());
            },
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: brand.primaryGradient,
              ),
              child: const Center(
                child: Text(
                  "Continue  →",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

