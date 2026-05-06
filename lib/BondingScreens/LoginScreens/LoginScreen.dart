// lib/screens/login_screen.dart
import 'package:bonding_app/BondingScreens/LoginScreens/LoginOtpScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/ui/app_gradient_button.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final colorScheme = Theme.of(context).colorScheme;
        return AppScaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Image.asset(
                      "assets/Images/bonding.png",
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
                      "What’s your number?",
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(height: 8),
                    AppText(
                      "Please enter a valid phone number. We will send you the 4 digit code to verify your account.",
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 25),

                    AppText(
                      "Phone number",
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: colorScheme.onSurface),
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                      decoration: const InputDecoration(
                        hintText: "Enter mobile number",
                        counterText: "",
                        prefixIcon: Icon(Icons.phone_android_rounded),
                      ),
                    ),

                    const SizedBox(height: 30),

                    AppGradientButton(
                      onPressed: vm.isLoading
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
                                bondNavigator.newPage(
                                  context,
                                  page: LoginOtpScreen(phoneNumber: phone),
                                );
                              } else {
                                Utils.topError(
                                  vm.errorMessage ?? "Failed to send OTP",
                                );
                              }
                            },
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
                              "Get OTP →",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
}
