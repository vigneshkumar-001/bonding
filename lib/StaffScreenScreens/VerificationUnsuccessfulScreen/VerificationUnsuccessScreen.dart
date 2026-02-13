import 'package:bonding_app/BondingScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen2.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VerificationUnsuccessScreen extends StatefulWidget {
  const VerificationUnsuccessScreen({super.key});

  @override
  State<VerificationUnsuccessScreen> createState() => _VerificationUnsuccessScreenState();
}

class _VerificationUnsuccessScreenState extends State<VerificationUnsuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xFF140810),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /// 🔹 Logo
                SvgPicture.asset(
                  "assets/Images/bonding.svg",
                  height: 35,
                ),

                SizedBox(height: 30,),
                Center(child: Image.asset("assets/Images/cancel.png",height: 200,)),

                const SizedBox(height: 20),

                /// 🔹 Title
                Center(
                  child: AppText(
                    "Verification Unsuccessful",
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 Description
                Center(
                  child: AppText(
                    "Our verification request could not be approved due to policy or document issues. You may review the reason below and try again.",
                    color: const Color(0XFFc7c7cc),
                    fontSize: 16,
                    maxLines: 5,
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                /// 🔹 Add Photo Button




              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:  SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GestureDetector(
            onTap: () {
              bondNavigator.replacePage(context, page: SplashScreen2());
            },
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB86AF6),
                    Color(0xFFFF6A6A),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  "Try again  →",
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
