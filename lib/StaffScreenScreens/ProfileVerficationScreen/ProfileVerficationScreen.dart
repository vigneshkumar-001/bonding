
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ProfileVerficationScreen extends StatefulWidget {
  const ProfileVerficationScreen({super.key});

  @override
  State<ProfileVerficationScreen> createState() => _ProfileVerficationScreenState();
}

class _ProfileVerficationScreenState extends State<ProfileVerficationScreen> {
  final TextEditingController idTypeController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController();

  String? _selectedIdType;
  String? _idNumberError;

  final List<String> idTypes = [
    "Aadhar Card",
    "Pan Card",
  ];

  @override
  void initState() {
    super.initState();
    idTypeController.text = "Aadhar Card"; // Default selection
    _selectedIdType = "Aadhar Card";
    idNumberController.addListener(_validateIdNumber);
  }

  @override
  void dispose() {
    idTypeController.dispose();
    idNumberController.removeListener(_validateIdNumber);
    idNumberController.dispose();
    super.dispose();
  }

  void _validateIdNumber() {
    final value = idNumberController.text.trim();
    String? error;

    if (_selectedIdType == "Aadhar Card") {
      if (value.isEmpty) {
        error = "Please enter Aadhaar number";
      } else if (value.length != 12 || !RegExp(r'^\d{12}$').hasMatch(value)) {
        error = "Aadhaar must be exactly 12 digits";
      }
    } else if (_selectedIdType == "Pan Card") {
      if (value.isEmpty) {
        error = "Please enter PAN number";
      } else if (value.length != 10 ) {
        error = "Invalid PAN format (e.g., ABCDE1234F)";
      }
    }

    setState(() {
      _idNumberError = error;
    });
  }

  bool get _isFormValid {
    final idType = idTypeController.text.trim();
    final idNumber = idNumberController.text.trim();

    if (idType.isEmpty) return false;
    if (idNumber.isEmpty) return false;

    if (idType == "Aadhar Card") {
      return idNumber.length == 12 && RegExp(r'^\d{12}$').hasMatch(idNumber);
    } else if (idType == "Pan Card") {
      return idNumber.length == 10 && RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(idNumber.toUpperCase());
    }

    return false;
  }

  void _showIDTypeDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF231d1d),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ...idTypes.map((type) => _dropdownItem(type, () {
              setState(() {
                _selectedIdType = type;
                idTypeController.text = type;
              });
              _validateIdNumber(); // Re-validate number format after type change
              Navigator.pop(context);
            })),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _dropdownItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF140810),
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
                        "Profile Verification Screen",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: AppText(
                        "Complete verification to activate your account.",
                        fontSize: 15,
                        color: const Color(0xFFc7c7cc),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── ID Type Dropdown ──────────────────────────────────────
                    AppText("ID Type:", color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showIDTypeDropdown(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: idTypeController,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Select ID Type",
                            hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                            filled: true,
                            fillColor: const Color(0xFF231d1d),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                "assets/Images/drop.svg",
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
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── ID Number with Real-time Validation ──────────────────
                    AppText("ID Number:", color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    const SizedBox(height: 8),
                    TextField(
                      controller: idNumberController,
                      keyboardType: _selectedIdType == "Aadhar Card" ? TextInputType.text : TextInputType.text,
                      textCapitalization: _selectedIdType == "Pan Card" ? TextCapitalization.characters : TextCapitalization.none,
                      maxLength: _selectedIdType == "Aadhar Card" ? 12 : 10,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _selectedIdType == "Aadhar Card" ? "Enter 12-digit Aadhaar" : "Enter PAN (e.g., ABCDE1234F)",
                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc)),
                        filled: true,
                        fillColor: const Color(0xFF231d1d),
                        errorText: _idNumberError,
                        errorStyle: const TextStyle(color: Colors.redAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (vm.idVerifyError != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.idVerifyError!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          "Note:",
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: AppText(
                            "Your documents are secure and used only for verification purposes.",
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFFc7c7cc),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // ─── Bottom Continue Button (disabled until valid) ────────────────
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: vm.isVerifyingId || !_isFormValid
                    ? null
                    : () async {
                  final success = await vm.verifyStaffId(
                    idType: idTypeController.text.trim(),
                    idNumber: idNumberController.text.trim(),
                  );

                  if (success) {
                    bondNavigator.newPage(
                      context,
                      page: const LiveVerificationScreen(),
                    );
                  } else {
                    Utils.snackBarErrorMessage("ID verification failed. Please try again.");
                  }
                },
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: (vm.isVerifyingId || !_isFormValid)
                        ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
                        : const LinearGradient(colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)]),
                  ),
                  child: Center(
                    child: vm.isVerifyingId
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
            ),
          ),
        );
      },
    );
  }
}