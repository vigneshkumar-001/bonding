import 'dart:ui';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/Transactions/TransactionDetailScreen.dart';
import 'package:bonding_app/BondingScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // for date formatting

class TransactionsScreen extends StatefulWidget {
  final bool backPage;
  const TransactionsScreen({super.key, required this.backPage});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    // Fetch data on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DepositHistoryViewModel>().fetchDepositHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DepositHistoryViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF100a0a),
            child: SafeArea(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : vm.errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vm.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: vm.refresh,
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
                             onTap: () => bondNavigator.newPageRemoveUntil(context, page: MainBottomBar(index: 0,)),
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
                              AppText("Transactions", fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
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

                  // Filters (you can make them functional later)
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

                  // Transactions List
                  Expanded(
                    child: vm.depositHistory.isEmpty
                        ? const Center(
                      child: Text(
                        "No transactions yet",
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: vm.depositHistory.length,
                      itemBuilder: (context, index) {
                        final txn = vm.depositHistory[index];

                        return GestureDetector(
                          onTap: () {
                            bondNavigator.newPage(
                              context,
                              page: TransactionDetailsScreen(transaction: txn),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Profile Image (can be user or payment icon)
                                // Replace the CircleAvatar with this:
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: txn.image != null && txn.image!.isNotEmpty
                                      ? NetworkImage(txn.image!)                     // ← load from URL
                                      : const AssetImage("assets/Images/pooja.png"), // fallback
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        "ID: ${txn.razorpayOrderId.substring(0, 10)}...",
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      const SizedBox(height: 4),
                                      AppText(
                                        DateFormat('MMM dd, yyyy. h:mm a').format(txn.createdAt),
                                        color: const Color(0xFFc1c1c6),
                                        fontSize: 14,
                                      ),
                                    ],
                                  ),
                                ),

                                // Amount & Status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AppText(
                                      "₹${txn.totalAmount}",
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(height: 4),
                                    AppText(
                                      txn.statusText,
                                      color: txn.statusColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}