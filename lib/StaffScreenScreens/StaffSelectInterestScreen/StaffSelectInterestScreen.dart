import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
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

  late final List<bool> selectedCategories = List.filled(categories.length, false);

  int get selectedCount => selectedCategories.where((selected) => selected).length;
  bool get canProceed => selectedCount >= 3;

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        final brand = BrandTheme.of(context);
        final colorScheme = Theme.of(context).colorScheme;

        return AppScaffold(
          resizeToAvoidBottomInset: true,
          safeArea: true,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Image.asset("assets/Images/bonding.png", height: 35),
                const SizedBox(height: 30),
                Center(
                  child: AppText(
                    "Select your Interest",
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: AppText(
                    "Select a few of your interests to match with users who have similar things in common.",
                    fontSize: 15,
                    color: colorScheme.onSurfaceVariant,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected ? brand.primaryGradient : null,
                          color:
                              isSelected ? null : Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: !isSelected
                              ? Border.all(color: Colors.white24, width: 1)
                              : null,
                        ),
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                if (vm.interestError != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      vm.interestError!,
                      style: TextStyle(color: colorScheme.error, fontSize: 14),
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
                                  .where((e) => selectedCategories[e.key])
                                  .map((e) => e.value)
                                  .toList(),
                            );
                            if (!context.mounted) return;

                            if (success) {
                              Utils.snackBar("Interests saved successfully!");
                              bondNavigator.newPage(
                                context,
                                page: const StaffBottomBar(),
                              );
                            } else {
                              Utils.snackBarErrorMessage(
                                vm.interestError ??
                                    "Failed to save interests. Try again.",
                              );
                            }
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: canProceed && !vm.isUpdatingInterests
                            ? brand.primaryGradient
                            : const LinearGradient(
                                colors: [Colors.grey, Colors.blueGrey],
                              ),
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
        );
      },
    );
  }
}

