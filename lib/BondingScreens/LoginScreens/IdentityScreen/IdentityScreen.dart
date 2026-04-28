import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/InterestScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  bool isMale = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    dobController.dispose();
    super.dispose();
  }

  bool _isValidName(String name) =>
      name.trim().isNotEmpty && name.trim().length >= 2;
  bool _isValidBio(String bio) =>
      bio.trim().isNotEmpty && bio.trim().length >= 10;
  bool _isValidDob(String dob) => dob.trim().isNotEmpty;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      builder: (context, child) {
        final cs = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: cs,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      String formatted =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      dobController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);
        return AppScaffold(
          safeArea: true,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Image.asset("assets/Images/bonding.png", height: 35),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => bondNavigator.backPage(context),
                          child: Icon(Icons.arrow_back_ios, color: cs.onSurface),
                        ),
                        const SizedBox(width: 12),
                        AppText(
                          "Identify yourself",
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    AppText(
                      "Introduce yourself fill out the details so people know about you.",
                      fontSize: 15,
                      color: cs.onSurfaceVariant,
                      maxLines: 2,
                    ),

                    // const SizedBox(height: 24),
                    //
                    // AppText(
                    //   "I am a:",
                    //   color: Colors.white,
                    //   fontSize: 15,
                    //   fontWeight: FontWeight.w600,
                    // ),
                    //
                    // const SizedBox(height: 10),
                    //
                    // Row(
                    //   children: [
                    //     _genderButton("Male", isMale, () => setState(() => isMale = true)),
                    //     const SizedBox(width: 12),
                    //     _genderButton("Female", !isMale, () => setState(() => isMale = false)),
                    //   ],
                    // ),
                    const SizedBox(height: 30),
                    AppText(
                      "Name:",
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    AppText(
                      "Birthday:",
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      onTap: () => _selectDate(context),
                      controller: dobController,
                      readOnly: true,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText: "DD/MM/YYYY",
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/Images/calender.svg",
                            width: 20,
                            height: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    AppText(
                      "Bio:",
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      style: TextStyle(color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText:
                            "Ex: A coffee lover who enjoys late-night conversations.",
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    if (vm.bioError != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.bioError!,
                          style: TextStyle(color: cs.error, fontSize: 14),
                        ),
                      ),
                    ],
                    GestureDetector(
                      onTap: vm.isUpdatingBio
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final bio = bioController.text.trim();
                              final dob = dobController.text.trim();
                              final gender = isMale ? "Male" : "Female";

                              if (!_isValidDob(dob)) {
                                Utils.snackBarErrorMessage(
                                  "Please select your birthday",
                                );
                                return;
                              }
                              if (!_isValidName(name)) {
                                Utils.snackBarErrorMessage(
                                  "Please enter a valid name",
                                );
                                return;
                              }
                              if (!_isValidBio(bio)) {
                                Utils.snackBarErrorMessage(
                                  "Please write a short bio (min 10 chars)",
                                );
                                return;
                              }

                              final success = await vm.updateBioData(
                                name: name,
                                gender: '',
                                dob: dob,
                                bio: bio,
                              );

                              if (success) {
                                bondNavigator.newPageRemoveUntil(
                                  context,
                                  page: const InterestScreen(),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Failed to update profile. Try again.",
                                );
                              }
                            },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: vm.isUpdatingBio
                              ? LinearGradient(
                                  colors: [
                                    cs.surfaceContainerHighest,
                                    cs.surfaceContainerHighest,
                                  ],
                                )
                              : brand.primaryGradient,
                        ),
                        child: Center(
                          child: vm.isUpdatingBio
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Continue  →",
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
        );
      },
    );
  }

  Widget _genderButton(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isActive
                ? BrandTheme.of(context).primaryGradient
                : null,
            color: isActive
                ? null
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),
            border: isActive
                ? null
                : Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.55),
                  ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
