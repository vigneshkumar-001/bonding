// lib/BondingScreens/WalletScreen/StaffWalletScreen.dart

import 'dart:ui';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawRequestScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StaffWalletScreen extends StatefulWidget {
  const StaffWalletScreen({super.key});

  @override
  State<StaffWalletScreen> createState() => _StaffWalletScreenState();
}

class _StaffWalletScreenState extends State<StaffWalletScreen> {
  int _selectedTab = 0; // 0 = Total balance, 1 = Pending, 2 = Completed

  @override
  void initState() {
    super.initState();
    // Fetch withdrawal history on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().fetchStaffWithdrawHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(  // or StaffViewModel
      builder: (context, vm, child) {
        final staffVM = context.read<StaffViewModel>();
        final staff = staffVM.currentStaff;
        final totalBalance = staff!.pendingBalance??"0";
        String headerYear = DateFormat('yyyy').format(DateTime.now());
        String headerMonth = DateFormat('MMMM').format(DateTime.now());

        if (vm.withdrawHistory.isNotEmpty) {
          final latest = vm.withdrawHistory
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
          headerYear = DateFormat('yyyy').format(latest.createdAt);
          headerMonth = DateFormat('MMMM').format(latest.createdAt);
        }
        // final totalBalance = vm.totalBalance; // from viewmodel
        // final pendingBalance = vm.currentStaff?.pendingBalance ?? 0.0;

        return Scaffold(
            backgroundColor: const Color(0xFF100a0a),
            body: SafeArea(
            child: vm.isLoadingWithdraw
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : vm.withdrawError != null
        ? Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Text(vm.withdrawError!, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 16),
        ElevatedButton(
        onPressed: vm.fetchStaffWithdrawHistory,
        child: const Text("Retry"),
        ),
        ],
        ),
        )
            : Column(
        children: [
        // 🔹 Header
        Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
        children: [
        GestureDetector(
        onTap: () => bondNavigator.backPage(context),
        child: Container(
        decoration: BoxDecoration(
        color: const Color(0xFF35272d),
        borderRadius: BorderRadius.circular(40),
        ),
        child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
        ),
        ),
        ),
        const Spacer(),
        SvgPicture.asset("assets/Images/bonding.svg", height: 32),
        const Spacer(),
        const SizedBox(width: 30),
        ],
        ),
        ),

        // 🔹 Balance Card (dynamic)
        Stack(
        alignment: Alignment.center,
        children: [
        Image.asset(
        "assets/Images/walletframe.png",
        width: double.infinity,
        fit: BoxFit.cover,
        ),
        Positioned(
        top: 30,
        child: Column(
        children: [
        const Text(
        "Total balance",
        style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
        "₹$totalBalance",
        style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        ),
        ),
        ],
        ),
        ),
        // Tabs at bottom
        Positioned(
        bottom: 12,
        left: 16,
        right: 16,
        child: Row(
        children: [
        _tab("Total balance", _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
        _tab("Pending payo...", _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
        _tab("Completed p...", _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
        ],
        ),
        ),
        ],
        ),

        const SizedBox(height: 12),

        // 🔹 Withdraw Button
        GestureDetector(
        onTap: () {
        bondNavigator.newPage(context, page: const WithdrawalRequestScreen());
        },
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 45,
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
        colors: [Color(0xFFB86AF6), Color(0xFFFF6A6A)],
        ),
        ),
        child: const Center(
        child: Text(
        "withdraw",
        style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        ),
        ),
        ),
        ),
        ),

        const SizedBox(height: 16),

        // 🔹 List Header (dynamic month/year)
        Container(
        color: const Color(0xFF282323),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
        children: [
        Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        AppText(
          headerYear, // TODO: dynamic from first txn date or current year
        color: Colors.white70,
        ),
        AppText(
          headerMonth, // TODO: dynamic
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        ),
        ],
        ),
        const Spacer(),
        Text(
        "₹${vm.withdrawHistory.fold<double>(0.0, (sum, txn) => sum + txn.amount)}",
        style: const TextStyle(
        color: Colors.green,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        ),
        ),
        ],
        ),
        ),
        ),

        const SizedBox(height: 10),

        // 🔹 Transaction List (dynamic withdrawals)
        Expanded(
        child: vm.withdrawHistory.isEmpty
        ? const Center(
        child: Text(
        "No withdrawals yet",
        style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        )
            : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vm.withdrawHistory.length,
        itemBuilder: (context, index) {

        final txn = vm.withdrawHistory[index];


        return _TransactionItem(
        title: txn.upi != null && txn.upi!.isNotEmpty ? "UPI transfer" : "Bank transfer",
        status: txn.status.toLowerCase(),
        amount: "₹${txn.amount}",
        date: DateFormat('dd MMMM').format(txn.createdAt),
        );
        },
        ),
        ),
        ],
        )));
        },
    );
  }

  static Widget _tab(String text, bool active, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active ? Colors.white : Colors.transparent,
            border: active ? null : Border.all(color: Colors.white24, width: 1),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Updated Transaction Item
class _TransactionItem extends StatelessWidget {
  final String title;
  final String status;
  final String amount;
  final String date;

  const _TransactionItem({
    required this.title,
    required this.status,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == "pending";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              title.contains("UPI") ? Icons.qr_code : Icons.account_balance,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                color: Colors.white,
                fontSize: 16,
              ),
              Row(
                children: [
                  AppText(
                    status.toUpperCase(),
                    color: isPending ? Colors.orange : Colors.green,
                    fontSize: 14,
                  ),
                  AppText(
                    " · $date",
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          AppText(
            amount,
            color: Colors.white,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}