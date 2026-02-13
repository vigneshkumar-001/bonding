// lib/BondingScreens/WalletScreen/WithdrawAddBank.dart

import 'dart:ui';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WithdrawAddBank extends StatefulWidget {
  const WithdrawAddBank({super.key});

  @override
  State<WithdrawAddBank> createState() => _WithdrawAddBankState();
}

class _WithdrawAddBankState extends State<WithdrawAddBank> {
  int _selectedTab = 0; // 0 = Bank, 1 = UPI

  // Bank fields
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();

  // UPI field
  final _upiController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _submitDetails() {
    final vm = context.read<WalletViewModel>();

    if (_selectedTab == 0) {
      // Bank tab
      if (_accountNumberController.text.isEmpty ||
          _ifscController.text.isEmpty ||
          _accountHolderController.text.isEmpty ||
          _bankNameController.text.isEmpty) {
        Utils.snackBarErrorMessage("Please fill all bank details");
        return;
      }

      vm.addBankOrUpiDetails(
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim().toUpperCase(),
        bankHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        context: context,
      );
    } else {
      // UPI tab
      if (_upiController.text.isEmpty) {
        Utils.snackBarErrorMessage("Please enter UPI ID");
        return;
      }

      vm.addBankOrUpiDetails(
        upi: _upiController.text.trim(),
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF140810),
                    Color(0xFF3A152A),
                    Color(0xFF140810),
                    Color(0xFF140810),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back + Title
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => bondNavigator.backPage(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF282323),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                    Icons.arrow_back, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          AppText(
                            "Add Bank / UPI",
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Tabs: Bank Account | UPI
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 0 ? const Color(
                                        0xFF9251d0) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: AppText(
                                      "Bank Account",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == 1 ? const Color(
                                        0xFF9251d0) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: AppText(
                                      "UPI",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Fields (dynamic based on tab)
                      if (_selectedTab == 0) ...[
                        // Bank Account Fields
                        _buildTextField(
                          controller: _accountHolderController,
                          label: "Account Holder Name",
                          hint: "Enter Name",
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _accountNumberController,
                          label: "Account Number",
                          hint: "XXXXXXXXXXXX",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _ifscController,
                          label: "IFSC Code",
                          hint: "SBIN0001234",
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _bankNameController,
                          label: "Bank Name",
                          hint: "HDFC Bank",
                        ),
                      ] else
                        ...[
                          // UPI Field
                          _buildTextField(
                            controller: _upiController,
                            label: "UPI ID",
                            hint: "yourname@upi",
                          ),
                        ],

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: vm.isLoading ? null : _submitDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9251d0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: vm.isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                              : const Text(
                            "Save Details",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Important Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.yellow[700],
                                size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Bank/UPI details are required for withdrawal. Ensure accuracy. Verification may take 24-48 hours.",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
        }

        // Reusable Text Field
        Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label, color: Colors.white70, fontSize: 14),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
                  ),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }