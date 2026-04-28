// lib/BondingScreens/WalletScreen/StaffWalletScreen.dart

import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawRequestScreen.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
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
    return Consumer<WalletViewModel>(
      builder: (context, vm, child) {
        final staffVM = context.read<StaffViewModel>();
        final staff = staffVM.currentStaff;
        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);

        if (staff == null) {
          return AppScaffold(
            body: Center(
              child: Text(
                "No profile data",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          );
        }

        final totalBalance = (staff.pendingBalance ?? 0).toStringAsFixed(2);
        String headerYear = DateFormat('yyyy').format(DateTime.now());
        String headerMonth = DateFormat('MMMM').format(DateTime.now());

        if (vm.withdrawHistory.isNotEmpty) {
          final latest = vm.withdrawHistory
              .reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
          headerYear = DateFormat('yyyy').format(latest.createdAt);
          headerMonth = DateFormat('MMMM').format(latest.createdAt);
        }

        return AppScaffold(
          body: vm.isLoadingWithdraw
              ? const AppLoader.center()
              : vm.withdrawError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vm.withdrawError!,
                            style: TextStyle(color: cs.error),
                            textAlign: TextAlign.center,
                          ),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => bondNavigator.backPage(context),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: cs.onSurface,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Image.asset("assets/Images/bonding.png", height: 32),
                              const Spacer(),
                              const SizedBox(width: 30),
                            ],
                          ),
                        ),

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
                                  Text(
                                    "Total balance",
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "₹$totalBalance",
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  _tab(
                                    "Total balance",
                                    _selectedTab == 0,
                                    onTap: () => setState(() => _selectedTab = 0),
                                  ),
                                  _tab(
                                    "Pending payo...",
                                    _selectedTab == 1,
                                    onTap: () => setState(() => _selectedTab = 1),
                                  ),
                                  _tab(
                                    "Completed p...",
                                    _selectedTab == 2,
                                    onTap: () => setState(() => _selectedTab = 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap: () {
                            bondNavigator.newPage(
                              context,
                              page: const WithdrawalRequestScreen(),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: brand.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                "Withdraw",
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(headerYear, color: cs.onSurfaceVariant),
                                    AppText(
                                      headerMonth,
                                      color: cs.onSurface,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  "₹${vm.withdrawHistory.fold<double>(0.0, (sum, txn) => sum + txn.amount).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: brand.online,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: vm.withdrawHistory.isEmpty
                              ? Center(
                                  child: Text(
                                    "No withdrawals yet",
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 18,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: vm.withdrawHistory.length,
                                  itemBuilder: (context, index) {
                                    final txn = vm.withdrawHistory[index];

                                    return _TransactionItem(
                                      title: txn.upi != null && txn.upi!.isNotEmpty
                                          ? "UPI transfer"
                                          : "Bank transfer",
                                      status: txn.status.toLowerCase(),
                                      amount: "₹${txn.amount}",
                                      date: DateFormat('dd MMMM').format(txn.createdAt),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _tab(String text, bool active, {VoidCallback? onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: active ? cs.surface : Colors.transparent,
            border: active
                ? null
                : Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                    width: 1,
                  ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: active ? cs.onSurface : cs.onSurfaceVariant,
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
    final cs = Theme.of(context).colorScheme;
    final brand = BrandTheme.of(context);
    final isPending = status == "pending";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            child: Icon(
              title.contains("UPI") ? Icons.qr_code : Icons.account_balance,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                color: cs.onSurface,
                fontSize: 16,
              ),
              Row(
                children: [
                  AppText(
                    status.toUpperCase(),
                    color: isPending ? cs.tertiary : brand.online,
                    fontSize: 14,
                  ),
                  AppText(
                    " · $date",
                    color: cs.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          AppText(
            amount,
            color: cs.onSurface,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}
