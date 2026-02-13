import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/AddProfileScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class LoginOtpStaffScreen extends StatefulWidget {
  final String phoneNumber;

  const LoginOtpStaffScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<LoginOtpStaffScreen> createState() => _LoginOtpStaffScreenState();
}

class _LoginOtpStaffScreenState extends State<LoginOtpStaffScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LoginViewModel>(context, listen: false);

      if (vm.autoOtp != null) {
        _otpController.text = vm.autoOtp!;
        setState(() {}); // refresh hearts
      }

      _focusNode.requestFocus();
    });
  }
  void _handleOtpFill() {
    final vm = Provider.of<LoginViewModel>(context, listen: false);

    if (vm.autoOtp != null &&
        _otpController.text != vm.autoOtp) {
      _otpController.text = vm.autoOtp!;
      setState(() {});
    }
  }


  @override
  void dispose() {
    final vm = Provider.of<LoginViewModel>(context, listen: false);
    vm.removeListener(_handleOtpFill);

    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }



  bool _isValidOtp(String otp) => RegExp(r'^\d{4}$').hasMatch(otp);

  // Method to open keyboard
  void _openKeyboard() {
    _focusNode.requestFocus();
    // Force keyboard to show
    SystemChannels.textInput.invokeMethod('TextInput.show');
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
                    SvgPicture.asset("assets/Images/bonding.svg", height: 35, width: 35),
                    const SizedBox(height: 30),
                    Center(child: Image.asset("assets/Images/phone1.png", width: 280)),
                    const SizedBox(height: 30),

                    AppText("Enter your code", fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                    const SizedBox(height: 16),

                    const Text("Enter OTP:", style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),

                    // OTP Input Section
                    Column(
                      children: [
                        // Hidden TextField for input
                        SizedBox(
                          height: 1,
                          child: TextField(
                            cursorColor: Colors.transparent,
                            controller: _otpController,
                            focusNode: _focusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
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

                        // Heart Display (Clickable)
                        Row(
                          children: [
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

                    // Login Button
                    GestureDetector(
                      onTap: vm.isVerifying
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

                        final success = await vm.staffVerifyOtp(
                          widget.phoneNumber,
                          otp,
                        );

                        if (success) {
                          bondNavigator.newPageRemoveUntil(
                            context,
                            page: const ProfileVerficationScreen(),
                          );
                        } else {
                          Utils.snackBarErrorMessage("Invalid OTP. Please try again.");
                        }
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: vm.isVerifying
                              ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                              : const LinearGradient(
                            colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
                          ),
                        ),
                        child: Center(
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

                    // Keyboard Toggle Button (Optional)
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
              const Icon(
                Icons.favorite,
                color: Color(0xFF322129),
                size: 70,
              ),
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