// lib/screens/wallet_screen.dart

import 'dart:ui';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Fetch real packages on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().fetchPaymentStructure();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _openCheckout(PaymentPackage package) {
    final vm = context.read<WalletViewModel>();

    final amountInRupees = int.parse(package.amount.toString());
    final coins = int.parse(package.coin);


    vm.placeCoinOrder(
      amountInRupees: amountInRupees,
      currency: 'INR',
      coins: coins,
    ).then((response) {
      if (response != null && response.data != null) {
        final orderId = response.data!.razorpayOrderId;

        var options = {
          'key': 'rzp_test_S8pViJJW5CVujd',
          'amount': amountInRupees * 100, // Razorpay expects paise
          'name': 'Bonding App',
          'description': '${package.coin} Coins Package',
          'order_id': orderId,
          'prefill': {
            'contact': '9952225025',
            'email': 'user@example.com',
          },
          'external': {'wallets': ['phonepe']},
          'theme': {'color': '#cc529f'},
        };

        try {
          _razorpay.open(options);
        } catch (e) {
          Utils.snackBarErrorMessage('Failed to open payment: $e');
        }
      }
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final vm = context.read<WalletViewModel>();

    vm.confirmPaymentAndCreditCoins(
      orderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );

    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message ?? 'Unknown error'}')),
    );
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened external wallet: ${response.walletName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WalletViewModel, UserViewModel>(
      builder: (context, vm, userVM, child) {
        final currentUser = userVM.currentUser;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF140810), Color(0xFF3A152A), Color(0xFF140810)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF282323),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.arrow_back, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppText("Wallet", fontSize: 18, fontWeight: FontWeight.w700),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(colors: [Color(0xFFcc529f), Color(0xFFf86460)]),
                              ),
                              child: Row(
                                children: [
                                  Image.asset("assets/Images/goldcoin1.png", height: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${currentUser?.coinBalance ?? 0}.00",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Image.asset("assets/Images/offer.png"),
                        const SizedBox(height: 20),

                        if (vm.isLoadingPackages)
                          const Center(child: CircularProgressIndicator(color: Colors.white))
                        else if (vm.packagesError != null)
                          Center(
                            child: Column(
                              children: [
                                Text(vm.packagesError!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: vm.fetchPaymentStructure,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        else if (vm.paymentPackages.isEmpty)
                            const Center(child: Text("No packages available", style: TextStyle(color: Colors.white70)))
                          else
                            Expanded(
                              child: GridView.builder(
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.95,
                                ),
                                itemCount: vm.paymentPackages.length,
                                itemBuilder: (context, index) {
                                  final package = vm.paymentPackages[index];
                                  final amount = int.parse(package.amount.toString());
                                  final coins = int.parse(package.coin);
                                  final hasDiscount = package.offerStatus == "true" && package.offerAmount != "0";
                                  final displayPrice = hasDiscount ? int.parse(package.offerAmount) : amount;
                                  final originalPrice = hasDiscount ? amount : null;

                                  return GestureDetector(
                                    onTap: vm.isLoading ? null : () => _openCheckout(package),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: Column(
                                          children: [
                                            if (hasDiscount)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(colors: [Color(0xFF8e51d2), Color(0xFFc450a7)]),
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(12),
                                                    topRight: Radius.circular(12),
                                                  ),
                                                ),
                                                child:  Center(
                                                  child: Text(
                                                    "FLAT ₹${displayPrice} OFF",
                                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              )
                                            else
                                              const SizedBox(height: 25),

                                            Container(
                                              height: 80,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: const Color(0xFF604b56)),
                                                borderRadius: BorderRadius.circular(14),
                                                gradient: LinearGradient(
                                                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Image.network(package.image, height: 40, errorBuilder: (_, __, ___) => Image.asset("assets/Images/coinglow.png", height: 40)),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "${package.coin}",
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                        if (originalPrice != null)
                                                          Text(
                                                            "₹$originalPrice",
                                                            style: const TextStyle(
                                                              color: Colors.white54,
                                                              fontSize: 11,
                                                              decoration: TextDecoration.lineThrough,
                                                            ),
                                                          ),
                                                        Text(
                                                          "₹$displayPrice",
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: hasDiscount ? Colors.yellow : Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      ],
                    ),

                    // Loading overlay
                    if (vm.isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
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