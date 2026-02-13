import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/AddProfileScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const LoginOtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LoginViewModel>(context, listen: false);

      if (vm.autoOtp != null) {
        _otpController.text = vm.autoOtp!;
        setState(() {}); // refresh hearts
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidOtp(String otp) => RegExp(r'^\d{4}$').hasMatch(otp);

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

                    // This is the key part: A transparent TextField positioned over the hearts
                    Stack(
                      children: [
                        // Heart display (non-interactive)
                        Row(
                          children: [
                            HeartOtpDisplay(
                              length: 4,
                              controller: _otpController,
                            ),
                          ],
                        ),

                        // Transparent TextField for input
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _focusNode.requestFocus(),
                            child: Container(
                              height: 70, // Match heart height
                              color: Colors.transparent,
                              child: TextField(
                                controller: _otpController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                style: const TextStyle(
                                  fontSize: 1, // Very small text (invisible)
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

                        if (success) {
                          bondNavigator.newPageRemoveUntil(
                            context,
                            page: const AddProfile(),
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
          padding: const EdgeInsets.only(right: 1),
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