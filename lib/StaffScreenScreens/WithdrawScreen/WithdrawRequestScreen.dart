// lib/BondingScreens/WalletScreen/WithdrawalRequestScreen.dart

import 'dart:ui';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/BankDetailModel.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/StaffWithdrawScreen.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  State<WithdrawalRequestScreen> createState() => _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  bool _isUpiSelected = true;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().fetchBankDetails();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BankDetailItem detail) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF231d1d),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Detail?", style: TextStyle(color: Colors.white)),
        content: Text(
          detail.isUpi
              ? "Delete UPI: ${detail.upi ?? 'N/A'}?"
              : "Delete Bank: ****${detail.accountNumber?.substring(detail.accountNumber!.length - 4) ?? 'N/A'}?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final vm = context.read<WalletViewModel>();
      await vm.deleteBankDetail(detail.id);
    }
  }

  void _submitWithdrawal() {
    final vm = context.read<WalletViewModel>();

    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
      Utils.snackBarErrorMessage("Please enter a valid amount");
      return;
    }

    final amount = int.parse(_amountController.text);

    // Use first saved detail (you can add selection later)
    if (vm.bankDetails.isEmpty) {
      Utils.snackBarErrorMessage("No saved bank/UPI details. Please add one first.");
      return;
    }

    final detail = vm.bankDetails.first; // or selected one

    vm.submitStaffWithdrawal(
      accountNumber: detail.accountNumber ?? '',
      confirmAccountNumber: detail.accountNumber ?? '',
      ifsc: detail.ifsc ?? '',
      bankHolderName: detail.bankHolderName ?? '',
      bankName: detail.bankName ?? '',
      upi: detail.upi ?? '',
      confirmUpi: detail.upi ?? '',
      amount: amount,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, child) {
        final hasDetails = vm.bankDetails.isNotEmpty;

        return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF140810), Color(0xFF3A152A), Color(0xFF140810), Color(0xFF140810)],
                ),
              ),
              child: SafeArea(
                child: vm.isFetchingBankDetails
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // Back + Title
                    Row(
                    children: [
                    GestureDetector(
                    onTap: () => bondNavigator.backPage(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              AppText(
                "Withdrawal Request",
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              ],
            ),

            const SizedBox(height: 32),

            // No details → Add prompt
            if (!hasDetails)
        GestureDetector(
          onTap: () {
            bondNavigator.newPage(context, page: const WithdrawAddBank());
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.yellow[700], size: 48),
                const SizedBox(height: 16),
                AppText(
                  "No Bank / UPI Details Added",
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                AppText(
                  "Add your bank account or UPI ID to withdraw earnings",
                  fontSize: 14,
                  color: Colors.white70,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9251d0), Color(0xFFf56463)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Add Bank / UPI",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        )
        else ...[
        // Saved Details List with Delete
        Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        AppText(
        "Saved Account Details",
        fontSize: 16,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 12),

        ...vm.bankDetails.map((detail) {
        return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        children: [
        Icon(
        detail.isUpi ? Icons.qr_code_rounded : Icons.account_balance,
        color: Colors.white70,
        size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        AppText(
        detail.isUpi ? "UPI ID" : "Bank",
        fontSize: 14,
        color: Colors.white70,
        ),
        const SizedBox(height: 4),
        AppText(
        detail.displayText,
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
        ),
        ],
        ),
        ),
        GestureDetector(
        onTap: () => _confirmDelete(detail),
        child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
        Icons.delete_outline,
        color: Colors.redAccent,
        size: 20,
        ),
        ),
        ),
        ],
        ),
        ),
        );
        }).toList(),
        ],
        ),
        ),

        const SizedBox(height: 24),

        // Enter Amount
        Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        AppText(
        "Enter Amount (₹)",
        fontSize: 16,
        color: Colors.white70,
        fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 12),
        ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
        height: 52,
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        gradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)],
        ),
        ),
        child: TextField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.left,
        style: const TextStyle(
        color: Colors.white,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
        hintText: "Enter amount",
        hintStyle: TextStyle(color: Colors.white38, fontSize: 18),
        prefixText: "₹ ",
        prefixStyle: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical:6),
        ),
        ),
        ),
        ),
        ),
        ],
        ),
        ),

        const SizedBox(height: 32),

        // Confirm & Cancel Buttons
        Row(
        children: [
        Expanded(
        child: GestureDetector(
        onTap: () => bondNavigator.backPage(context),
        child: Container(
        height: 48,
        decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
        child: Text(
        "cancel",
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        ),
        ),
        ),
        ),
        const SizedBox(width: 16),
        Expanded(
        child: GestureDetector(
        onTap: vm.isLoading
        ? null
            : _submitWithdrawal,
        child: Container(
        height: 48,
        decoration: BoxDecoration(
        gradient: const LinearGradient(
        colors: [Color(0xFF9251d0), Color(0xFFf56463)],
        ),
        borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
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
        "confirm",
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        ),
        ),
        ),
        ),
        ],
        ),

        const SizedBox(height: 32),

        // Withdrawal History Footer
        GestureDetector(
        onTap: () {
        // TODO: Navigate to history page
        },
        child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
        colors: [Color(0xFF251528), Color(0xFF341818)],
        ),
        ),
        child: Center(
        child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: AppText(
        "Withdrawal history",
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        ),
        ),
        ),
        ),
        ),

        const SizedBox(height: 40),
        ],
        ]),
        ),
        ),

        ),
        );
      });


  }

  Widget _buildAccountDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(title, fontSize: 14, color: Colors.white70),
              const SizedBox(height: 4),
              AppText(value, fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ],
    );
  }
}