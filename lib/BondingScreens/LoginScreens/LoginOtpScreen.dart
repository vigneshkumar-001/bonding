import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/AddProfileScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/ui/app_gradient_button.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidOtp(String otp) => RegExp(r'^\d{4}$').hasMatch(otp);

  void _openKeyboard() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
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
                Image.asset("assets/Images/bonding.png", height: 35, width: 35),
                const SizedBox(height: 30),
                Center(
                  child: Image.asset("assets/Images/phone1.png", width: 280),
                ),
                const SizedBox(height: 30),

                AppText(
                  "Enter your code",
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(height: 16),

                AppText(
                  "Enter OTP",
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(height: 12),

                // This is the key part: A transparent TextField positioned over the hearts
                Column(
                  children: [
                    // Hidden TextField to capture input & show keyboard
                    SizedBox(
                      height: 1,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        style: const TextStyle(
                          fontSize: 1,
                          color: Colors.transparent,
                        ),
                        cursorColor: Colors.transparent,
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
                      child: HeartOtpDisplay(length: 4, controller: _otpController),
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

                AppGradientButton(
                  onPressed: vm.isVerifying
                      ? null
                      : () async {
                          final otp = _otpController.text.trim();

                          if (!_isValidOtp(otp)) {
                            Utils.snackBarErrorMessage(
                              "Enter valid 4 digit OTP",
                            );
                            return;
                          }

                          await vm.verifyOtp(widget.phoneNumber, otp);

                          if (!mounted) return;

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
                            Utils.snackBarErrorMessage(
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
                  child: vm.isVerifying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Login →",
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
          padding: const EdgeInsets.only(right: 1),
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
