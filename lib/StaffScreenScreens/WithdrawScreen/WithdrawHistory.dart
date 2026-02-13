// lib/BondingScreens/WalletScreen/WithdrawHistory.dart

import 'dart:ui';
import 'package:bonding_app/BondingScreens/Transactions/TransactionDetailScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class WithdrawHistory extends StatefulWidget {
  final bool backPage;
  const WithdrawHistory({super.key, required this.backPage});

  @override
  State<WithdrawHistory> createState() => _WithdrawHistoryState();
}

class _WithdrawHistoryState extends State<WithdrawHistory> {
  bool isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    // Fetch withdrawal history on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().fetchStaffWithdrawHistory();

    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF100a0a),
            child: SafeArea(
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
                      onPressed: vm.refreshWithdrawHistory,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
                  : Column(
                children: [
                  // Top Bar with Search
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                           widget.backPage? GestureDetector(
                              onTap: () => bondNavigator.backPage(context),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282323),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                                ),
                              ),
                            ):GestureDetector(
                             onTap: () => bondNavigator.newPageRemoveUntil(context, page: StaffBottomBar(index: 0,)),
                             child: Container(
                               decoration: BoxDecoration(
                                 color: const Color(0xFF282323),
                                 borderRadius: BorderRadius.circular(40),
                               ),
                               child: const Padding(
                                 padding: EdgeInsets.all(8.0),
                                 child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                               ),
                             ),
                           ),
                            if (isSearchVisible) ...[
                              const SizedBox(width: 15),
                              AppText("Withdrawal History", fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ],
                          ],
                        ),
                        if (!isSearchVisible)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF282223), Color(0xFF271c1f), Color(0xFF23121a)],
                                      ),
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                                    ),
                                    child: TextField(
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Search by “Transaction ID”',
                                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc), fontSize: 16),
                                        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 22),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => setState(() => isSearchVisible = !isSearchVisible),
                          child: Image.asset('assets/Images/search.png', color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Filters (placeholder – make functional later)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282323),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SvgPicture.asset("assets/Images/calendar.svg"),
                                    const SizedBox(width: 5),
                                    AppText("This month", color: Colors.white, fontSize: 14),
                                  ],
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282323),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText("Type", color: Colors.white, fontSize: 14),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282323),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText("Status", color: Colors.white, fontSize: 14),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Withdrawals List
                  Expanded(
                    child: vm.withdrawHistory.isEmpty
                        ? const Center(
                      child: Text(
                        "No withdrawal requests yet",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    )
                        : RefreshIndicator(
                      onRefresh: vm.refreshWithdrawHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: vm.withdrawHistory.length,
                        itemBuilder: (context, index) {
                          final txn = vm.withdrawHistory[index];

                          return GestureDetector(
                            onTap: () {
                              bondNavigator.newPage(
                                context,
                                page: WithdrawDetailScreen(transaction: txn),
                              );
                              // TODO: Go to detail screen if needed
                              // bondNavigator.newPage(context, page: WithdrawDetailScreen(txn: txn));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  // Profile / Bank Image
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: txn.image != null && txn.image!.isNotEmpty
                                        ? NetworkImage(txn.image!)
                                        : const AssetImage("assets/Images/bank_placeholder.png") as ImageProvider,
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          "ID: ${txn.id.substring(0, 10)}...",
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        const SizedBox(height: 4),
                                        AppText(
                                          DateFormat('MMM dd, yyyy • h:mm a').format(txn.createdAt),
                                          color: const Color(0xFFc1c1c6),
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Amount & Status
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      AppText(
                                        "₹${txn.amount}",
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: txn.statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          txn.statusText,
                                          style: TextStyle(
                                            color: txn.statusColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        );


      },
    );
  }
}