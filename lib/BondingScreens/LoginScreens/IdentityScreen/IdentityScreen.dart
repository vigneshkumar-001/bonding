import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/InterestScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
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

  bool _isValidName(String name) => name.trim().isNotEmpty && name.trim().length >= 2;
  bool _isValidBio(String bio) => bio.trim().isNotEmpty && bio.trim().length >= 10;
  bool _isValidDob(String dob) => dob.trim().isNotEmpty;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB86AF6),
              onPrimary: Colors.white,
              surface: Color(0xFF2A1A2A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6A6A)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      String formatted = "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      dobController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
              child: SingleChildScrollView(
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
                          "Identify yourself",
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    AppText(
                      "Introduce yourself fill out the details so people know about you.",
                      fontSize: 15,
                      color: const Color(0xFFc7c7cc),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    AppText(
                      "I am a:",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _genderButton("Male", isMale, () => setState(() => isMale = true)),
                        const SizedBox(width: 12),
                        _genderButton("Female", !isMale, () => setState(() => isMale = false)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    AppText(
                      "Birthday:",
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      onTap: () => _selectDate(context),
                      controller: dobController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "DD/MM/YYYY",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
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

                    if (vm.bioError != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.bioError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    AppText("Name:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    AppText("Bio:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Ex: A coffee lover who enjoys late-night conversations.",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: vm.isUpdatingBio
                          ? null
                          : () async {
                        final name = nameController.text.trim();
                        final bio = bioController.text.trim();
                        final dob = dobController.text.trim();
                        final gender = isMale ? "Male" : "Female";

                        if (!_isValidDob(dob)) {
                          Utils.snackBarErrorMessage("Please select your birthday");
                          return;
                        }
                        if (!_isValidName(name)) {
                          Utils.snackBarErrorMessage("Please enter a valid name");
                          return;
                        }
                        if (!_isValidBio(bio)) {
                          Utils.snackBarErrorMessage("Please write a short bio (min 10 chars)");
                          return;
                        }

                        final success = await vm.updateBioData(
                          name: name,
                          gender: gender,
                          dob: dob,
                          bio: bio,
                        );

                        if (success) {
                          bondNavigator.newPageRemoveUntil(
                            context,
                            page: const InterestScreen(),
                          );
                        } else {
                          Utils.snackBarErrorMessage("Failed to update profile. Try again.");
                        }
                      },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: vm.isUpdatingBio
                              ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                              : const LinearGradient(
                            colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
                          ),
                        ),
                        child: Center(
                          child: vm.isUpdatingBio
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
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
                ? const LinearGradient(colors: [Color(0xFF8f51d1), Color(0xFFc350a9)])
                : null,
            color: isActive ? null : const Color(0xFF5a344b),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
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