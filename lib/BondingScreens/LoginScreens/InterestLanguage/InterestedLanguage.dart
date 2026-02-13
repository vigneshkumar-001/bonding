import 'package:bonding_app/BondingScreens/LoginScreens/AllsetScreen/AllSetScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class InterestLanguageScreen extends StatefulWidget {
  const InterestLanguageScreen({super.key});

  @override
  State<InterestLanguageScreen> createState() => _InterestLanguageScreenState();
}

class _InterestLanguageScreenState extends State<InterestLanguageScreen> {
  final List<Map<String, dynamic>> languages = [
    {"title": "English", "active": "assets/Images/englishactive.png", "inactive": "assets/Images/englishinactive.png", "selected": false},
    {"title": "Tamil", "active": "assets/Images/tamilactive.png", "inactive": "assets/Images/tamilinactive.png", "selected": false},
    {"title": "Malayalam", "active": "assets/Images/malayalamactive.png", "inactive": "assets/Images/malayalaminactive.png", "selected": false},
    {"title": "Hindi", "active": "assets/Images/hindiactive.png", "inactive": "assets/Images/hindiinactive.png", "selected": false},
  ];

  String? get selectedLanguage {
    final selected = languages.firstWhere(
          (e) => e["selected"] == true,
      orElse: () => {"title": ""},
    );
    return selected["title"] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
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
                  Color(0xFF5A1F3F),
                  Color(0xFF140810),
                  Color(0xFF140810),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        SvgPicture.asset("assets/Images/bonding.svg", height: 35),
                        const SizedBox(height: 30),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => bondNavigator.backPage(context),
                              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            AppText(
                              "Select your Language",
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        AppText(
                          "Select a Few of your Language to match with users who have similar things in common.",
                          fontSize: 15,
                          color: const Color(0xFFc7c7cc),
                          maxLines: 2,
                        ),

                        if (vm.languageError != null) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              vm.languageError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        itemCount: languages.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, index) {
                          final item = languages[index];
                          return _languageCard(item, index);
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: GestureDetector(
                      onTap: vm.isUpdatingLanguage
                          ? null
                          : () async {
                        final lang = selectedLanguage;
                        if (lang == null || lang.isEmpty) {
                          Utils.snackBarErrorMessage("Please select a language");
                          return;
                        }

                        final success = await vm.updateUserLanguage(lang);

                        if (success) {
                          bondNavigator.newPageRemoveUntil(
                            context,
                            page: const AllsetScreen(),
                          );
                        } else {
                          Utils.snackBarErrorMessage("Failed to save language preference");
                        }
                      },
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: selectedLanguage != null
                              ? const LinearGradient(colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)])
                              : const LinearGradient(colors: [Color(0xFF353535), Color(0xFF353535)]),
                        ),
                        child: Center(
                          child: vm.isUpdatingLanguage
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : const Text(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _languageCard(Map<String, dynamic> item, int index) {
    final bool selected = item["selected"];

    return GestureDetector(
      onTap: () {
        setState(() {
          // Unselect all others
          for (var i = 0; i < languages.length; i++) {
            languages[i]["selected"] = false;
          }
          // Select current
          languages[index]["selected"] = true;
        });
      },
      child: Image.asset(
        selected ? item["active"] : item["inactive"],
      ),
    );
  }
}