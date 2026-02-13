import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class StaffInterestScreen extends StatefulWidget {
  const StaffInterestScreen({super.key});

  @override
  State<StaffInterestScreen> createState() => _StaffInterestScreenState();
}

class _StaffInterestScreenState extends State<StaffInterestScreen> {
  final List<String> categories = [
    "Low Confidence",
    "Relationship",
    "Stress",
    "Travel",
    "Music",
    "Anxiety",
  ];

  List<bool> selectedCategories = List.filled(6, false);

  int get selectedCount => selectedCategories.where((selected) => selected).length;

  bool get canProceed => selectedCount >= 3;

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF100a0a),
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    SvgPicture.asset("assets/Images/bonding.svg", height: 35),

                    const SizedBox(height: 30),

                    // Title
                    Center(
                      child: AppText(
                        "Select your Interest",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: AppText(
                        "Select a few of your interests to match with users who have similar things in common.",
                        fontSize: 15,
                        color: const Color(0xFFc7c7cc),
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Interest Chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(categories.length, (index) {
                        final isSelected = selectedCategories[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategories[index] = !isSelected;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                colors: [Color(0xFF8d51d2), Color(0xFFf8655f)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : null,
                              color: isSelected ? null : const Color(0xFF231d1d),
                              borderRadius: BorderRadius.circular(8), // pill shape
                              border: !isSelected
                                  ? Border.all(color: Colors.white.withOpacity(0.2), width: 1)
                                  : null,
                            ),
                            child: Text(
                              categories[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const Spacer(),

                    // Continue Button
                    if (vm.interestError != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.interestError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: vm.isUpdatingInterests || !canProceed
                            ? null
                            : () async {
                          final success = await vm.updateStaffAreaOfInterest(
                            categories
                                .asMap()
                                .entries
                                .where((entry) => selectedCategories[entry.key])
                                .map((entry) => entry.value)
                                .toList(),
                          );

                          if (success) {
                            Utils.snackBar("Interests saved successfully!");
                            bondNavigator.newPage(
                              context,
                              page: const StaffBottomBar(),
                            );
                          } else {
                            Utils.snackBarErrorMessage(
                              vm.interestError ?? "Failed to save interests. Try again.",
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: canProceed && !vm.isUpdatingInterests
                                ? const LinearGradient(colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)])
                                : const LinearGradient(colors: [Color(0xFF353535), Color(0xFF353535)]),
                          ),
                          child: Center(
                            child: vm.isUpdatingInterests
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : Text(
                              canProceed
                                  ? "Continue → ($selectedCount selected)"
                                  : "Select at least 3 interests",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}