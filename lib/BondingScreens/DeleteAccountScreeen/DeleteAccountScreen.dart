import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/DeleteReasonScreen.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart'; // If you use AppText
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart'; // For navigation

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100a0a), // Same background as ProfileScreen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            bondNavigator.backPage(context);
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF35272d),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure want to delete account ?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 32),

            // First bullet point
            _buildBulletPoint(
              "Information related to your account will be kept for 30 days\nand will be completely purged after no activity for continuous 30 days.",
            ),
            const SizedBox(height: 24),

            // Second bullet point
            _buildBulletPoint(
              "After the account is deleted, you will no longer be able to log in or use the account, and the account cannot be recovered.",
            ),

            const Spacer(),

            // Continue Button
            GestureDetector(
              onTap: () {
bondNavigator.newPage(context, page: DeleteReasonScreen());
              },
              child: Container(
                height: 45,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8d51d2),
                      Color(0xFFf8655f),
                    ],
                  ),
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF241628),
                      Color(0xFF2c1522),
                      Color(0xFF321818),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child:  ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      colors: [Color(0xFF9D4EDD), Color(0xFFFF5A5F)], // Same gradient as Continue button
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds);
                  },
                  child:  AppText(
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

  Widget _buildBulletPoint(String text) {
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}