// ignore_for_file: file_names

import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/AddProfileScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:provider/provider.dart';

import '../BottomNavBar/BottomNavBar.dart';

class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const LoginOtpScreen({super.key, required this.phoneNumber});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void _openKeyboard() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openKeyboard();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
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
              gradient: Apptheme.backgroundGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Image.asset(
                      "assets/Images/appLogo.png",
                      height: 35,
                      width: 35,
                      fit: BoxFit.contain,
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
                      "Enter your code",
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Enter OTP:",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: [
                        SizedBox(
                          height: 1,
                          child: TextField(
                            cursorColor: Colors.transparent,
                            controller: _otpController,
                            focusNode: _focusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            maxLength: 4,
                            enableSuggestions: false,
                            autocorrect: false,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: const TextStyle(
                              fontSize: 1,
                              color: Colors.transparent,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openKeyboard,
                          child: HeartOtpDisplay(
                            length: 4,
                            controller: _otpController,
                          ),
                        ),
                      ],
                    ),

                    // if (vm.verifyError != null) ...[
                    //   const SizedBox(height: 16),
                    //   Text(
                    //     vm.verifyError!,
                    //     style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    //     textAlign: TextAlign.center,
                    //   ),
                    // ],
                    const SizedBox(height: 40),

                    GestureDetector(
                      onTap: vm.isVerifying
                          ? null
                          : () async {
                              final otp = _otpController.text.trim();

                              if (otp.length != 4) {
                                Utils.snackBarErrorMessage(
                                  "Enter valid 4 digit OTP",
                                );
                                return;
                              }

                              await vm.verifyOtp(widget.phoneNumber, otp);

                              if (!mounted || !context.mounted) return;

                              final response = vm.verifyResponse;

                              if (response != null && response.isSuccess) {
                                final isLogin = response.user?.isLogin ?? false;

                                bondNavigator.newPageRemoveUntil(
                                  context,
                                  page: isLogin
                                      ? const MainBottomBar()
                                      : const AddProfile(),
                                );
                              } else {
                                // Surfaces the real server message (incl. admin
                                // block/delete "...blocked/removed by admin").
                                Utils.snackBarErrorMessage(
                                  vm.verifyError ??
                                      "Invalid OTP. Please try again.",
                                );
                              }
                            },

                      /* onTap: vm.isVerifying
                          ? null
                          : () async {
                        final otp = _otpController.text.trim();

                        if (otp.isEmpty) {
                          Utils.snackBarErrorMessage("Please enter the OTP");
                          return;
                        }
                        if (!_isValidOtp(otp)) {
                          Utils.snackBarErrorMessage("Please enter all 4 digits");
                          return;
                        }

                        final success = await vm.verifyOtp(
                          widget.phoneNumber,
                          otp,
                        );
                        final response = vm.verifyResponse;

                        if (response != null && response.isSuccess) {
                          final isLogin = response.user?.isLogin ?? false;

                          if (isLogin) {
                            bondNavigator.newPageRemoveUntil(
                              context,
                              page: const MainBottomBar(),
                            );
                          } else {
                            bondNavigator.newPageRemoveUntil(
                              context,
                              page: const AddProfile(),
                            );
                          }
                        } else {
                          Utils.snackBarErrorMessage("Invalid OTP. Please try again.");
                        }

                        // if (success) {
                        //   if(vm.verifyResponse?.user?.isLogin == false){
                        //   bondNavigator.newPageRemoveUntil(
                        //     context,
                        //     page: const AddProfile(),
                        //   );
                        //   }else{
                        //     bondNavigator.newPageRemoveUntil(
                        //       context,
                        //       page: const MainBottomBar(),
                        //     );
                        //   }
                        // } else {
                        //   Utils.snackBarErrorMessage("Invalid OTP. Please try again.");
                        // }
                      },*/
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: vm.isVerifying
                              ? Apptheme.buttonDisabledGradient
                              : Apptheme.buttonGradient,
                        ),
                        child: Center(
                          child: vm.isVerifying
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: AppLoadingIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Login  →",
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
                    Center(
                      child: TextButton(
                        onPressed: _openKeyboard,
                        child: const Text(
                          "Tap to open keyboard",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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

class HeartOtpDisplay extends StatelessWidget {
  final int length;
  final TextEditingController controller;

  const HeartOtpDisplay({
    super.key,
    required this.length,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final text = controller.text;
        final char = index < text.length ? text[index] : "-";

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.favorite, color: Color(0xFF322129), size: 70),
              Text(
                char,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
