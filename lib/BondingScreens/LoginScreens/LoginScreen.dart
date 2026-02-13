// lib/screens/login_screen.dart
import 'package:bonding_app/BondingScreens/LoginScreens/LoginOtpScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ← add provider to pubspec.yaml

import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
                    SvgPicture.asset(
                      "assets/Images/bonding.svg",
                      height: 35,
                      width: 35,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Image.asset(
                        "assets/Images/phone1.png",
                        width: 280,
                      ),
                    ),
                    const SizedBox(height: 30),

                    AppText(
                      "What’s your number ?",
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      "Please enter valid phone number. We will send you the 4 digit code to verify account.",
                      color: const Color(0xFFc7c7cc),
                      fontSize: 15,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      "Phone number:",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter mobile number",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: vm.isLoading
                          ? null
                          : () async {
                              final phone = _phoneController.text.trim();

                              if (phone.isEmpty) {
                                Utils.snackBarErrorMessage(
                                  "Please enter your phone number",
                                );
                                return;
                              }
                              if (!_isValidPhone(phone)) {
                                Utils.snackBarErrorMessage(
                                  "Enter a valid 10-digit phone number",
                                );
                                return;
                              }

                              final success = await context
                                  .read<LoginViewModel>()
                                  .sendOtp(phone);

                              if (success) {
                                // Optional: pass phone & expiry/otp for dev
                                bondNavigator.newPage(
                                  context,
                                  page: LoginOtpScreen(
                                    phoneNumber: _phoneController.text,
                                  ),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Failed to send OTP",
                                );
                              }
                            },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: vm.isLoading
                                ? [Colors.grey.shade700, Colors.grey.shade800]
                                : [
                                    const Color(0xFFB86AF6),
                                    const Color(0xFFf76461),
                                  ],
                          ),
                        ),
                        child: Center(
                          child: vm.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Get OTP  →",
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
