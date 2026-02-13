
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/VerifyOtpStaffScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class StaffRegisterScreen extends StatefulWidget {
  const StaffRegisterScreen({super.key});

  @override
  State<StaffRegisterScreen> createState() => _StaffRegisterScreenState();
}

class _StaffRegisterScreenState extends State<StaffRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool _isMale = true;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    dobController.dispose();
    super.dispose();
  }

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

  bool _isValidInput() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final city = cityController.text.trim();
    final dob = dobController.text.trim();

    if (name.isEmpty || name.length < 2) {
      Utils.snackBarErrorMessage("Please enter a valid name");
      return false;
    }
    if (phone.isEmpty || phone.length != 10) {
      Utils.snackBarErrorMessage("Please enter a valid 10-digit phone number");
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      Utils.snackBarErrorMessage("Please enter a valid email");
      return false;
    }
    if (city.isEmpty) {
      Utils.snackBarErrorMessage("Please enter your city");
      return false;
    }
    if (dob.isEmpty) {
      Utils.snackBarErrorMessage("Please select your date of birth");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
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

                    Center(
                      child: AppText(
                        "Staff registration",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    AppText(
                      "Join as a verified female staff member and start earning through audio and video calls.",
                      fontSize: 15,
                      color: const Color(0xFFc7c7cc),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // ─── Name ──────────────────────────────────────────────────
                    AppText("Name:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your name",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Date of Birth ────────────────────────────────────────
                    AppText("Date Of Birth:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      onTap: () => _selectDate(context),
                      controller: dobController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "DD/MM/YYYY",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
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

                    const SizedBox(height: 20),

                    // ─── Mobile Number ────────────────────────────────────────
                    AppText("Mobile number:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter 10-digit number",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        prefixText: "+91 ",
                        prefixStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Email ────────────────────────────────────────────────
                    AppText("Email Address:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "xyz@gmail.com",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── City ─────────────────────────────────────────────────
                    AppText("City:", color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cityController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter your city",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // ─── Continue Button ──────────────────────────────────────
                    GestureDetector(
                      onTap: vm.isRegistering
                          ? null
                          : () async {
                        if (!_isValidInput()) return;

                        final success = await vm.registerStaff(
                          phone: phoneController.text.trim(),
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          city: cityController.text.trim(),
                          dob: dobController.text.trim(),
                        );

                        if (success) {
                          // Pass OTP & phone to next screen for verification
                          bondNavigator.newPage(
                            context,
                            page: LoginOtpStaffScreen(
                              phoneNumber: phoneController.text.trim(),
                              // otp: vm.registerResponse!.otp!,
                              // otpExpiresTime: vm.registerResponse!.otpExpiresTime!,
                            ),
                          );
                        } else {
                          Utils.snackBarErrorMessage("Registration failed. Please try again.");
                        }
                      },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: vm.isRegistering
                              ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                              : const LinearGradient(colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)]),
                        ),
                        child: Center(
                          child: vm.isRegistering
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                              : const Text(
                            "Continue to Verification  →",
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
}