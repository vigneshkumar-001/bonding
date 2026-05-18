import 'package:bonding_app/AccountSelectScreen/AccountSelectScreen.dart';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/LoginScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔹 Background Image
          Positioned.fill(
            child: Image.asset("assets/Images/Splash2.png", fit: BoxFit.cover),
          ),

          SafeArea(
            child: Column(
              children: [
                /// 🔹 App Logo (Top)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/Images/appLogo.png",
                        height: 35,
                        width: 35,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                /// 🔹 Push content to center
                const Spacer(),

                /// 🔹 Center Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          const TextSpan(
                            text: "Real ",
                            style: TextStyle(color: Colors.white),
                          ),

                          /// Gradient Text
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(
                                    colors: [
                                      Color(0xFFa551c1),
                                      Color(0xFFcb51a0),
                                    ],
                                  ).createShader(
                                    Rect.fromLTWH(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  ),
                              child: const Text(
                                "TwoOfUs",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const TextSpan(
                            text: " start here.",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Subtitle
                    AppText(
                      "Find people who match your vibe.",
                      color: Colors.white,
                      fontSize: 14,
                    ),

                    const SizedBox(height: 24),

                    /// Get Started Button
                    GestureDetector(
                      onTap: () {
                        bondNavigator.newPage(
                          context,
                          page: AccountSelectScreen(),
                        );
                      },
                      child: Container(
                        height: 45,
                        width: MediaQuery.of(context).size.width * 0.55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: Apptheme.buttonGradient,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Get started",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                /// 🔹 Bottom spacing
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
