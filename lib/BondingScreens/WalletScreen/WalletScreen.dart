// lib/screens/wallet_screen.dart

import 'dart:ui';

import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const String _rupee = '\u20B9';

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

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
    final userVM = context.read<UserViewModel>();
    final currentUser = userVM.currentUser;

    final amountInRupees = package.amount;
    final coins = int.tryParse(package.coin) ?? 0;

    vm
        .placeCoinOrder(
          amountInRupees: amountInRupees,
          currency: 'INR',
          coins: coins,
        )
        .then((response) {
          if (response != null && response.data != null) {
            final checkout = response.data?.checkout;
            final orderId = checkout?.orderId.isNotEmpty == true
                ? checkout!.orderId
                : response.data?.deposit?.razorpayOrderId ?? '';
            final checkoutKey = checkout?.key.isNotEmpty == true
                ? checkout!.key
                : checkout?.keyId ?? '';

            if (checkout == null || checkoutKey.isEmpty || orderId.isEmpty) {
              Utils.snackBarErrorMessage(
                'Payment setup failed. Please try again later.',
              );
              AppLogger.log.e(
                'Razorpay checkout data missing. '
                'key=$checkoutKey orderId=$orderId checkout=$checkout',
              );
              return;
            }

            final options = {
              'key': checkoutKey,
              'amount': checkout.amount > 0
                  ? checkout.amount
                  : amountInRupees * 100,
              'currency': checkout.currency,
              'name': checkout.name.isNotEmpty ? checkout.name : 'Bonding App',
              'description': '${package.coin} Coins Package',
              'order_id': orderId,
              'prefill': {
                'name': checkout.prefill?.name.isNotEmpty == true
                    ? checkout.prefill!.name
                    : (currentUser?.name ?? ''),
                'contact': checkout.prefill?.contact.isNotEmpty == true
                    ? checkout.prefill!.contact
                    : (currentUser?.phone ?? ''),
                'email': checkout.prefill?.email ?? '',
              },
              'external': {
                'wallets': ['phonepe'],
              },
              'theme': {'color': '#cc529f'},
            };

            AppLogger.log.w(options);
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
    AppLogger.log.i(response);
    vm.confirmPaymentAndCreditCoins(
      orderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );

    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? 'Unknown error'}'),
      ),
    );
    Navigator.pop(context);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened external wallet: ${response.walletName}')),
    );
  }

  int _crossAxisCount(double width) {
    if (width >= 1100) return 5;
    if (width >= 820) return 4;
    return 3;
  }

  double _gridAspectRatio(double width) {
    if (width >= 820) return 1.02;
    if (width >= 520) return 0.94;
    return 0.78;
  }

  Widget _buildPackageCard({
    required PaymentPackage package,
    required bool hasDiscount,
    required int displayPrice,
    required int? originalPrice,
    required bool isProcessing,
  }) {
    final offerLabel = originalPrice != null
        ? 'FLAT $_rupee${originalPrice - displayPrice} OFF'
        : '';

    return GestureDetector(
      onTap: isProcessing ? null : () => _openCheckout(package),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF604B56)),
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasDiscount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8E51D2), Color(0xFFC450A7)],
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        offerLabel,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Image.network(
                                package.image,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/Images/coinglow.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            package.coin,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                       
                        const SizedBox(height: 3),
                        if (originalPrice != null)
                          Text(
                            '$_rupee$originalPrice',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$_rupee$displayPrice',
                            maxLines: 1,
                            style: TextStyle(
                              color: hasDiscount
                                  ? const Color(0xFFFFE082)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WalletViewModel, UserViewModel>(
      builder: (context, vm, userVM, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF120C18),
                  Color(0xFF241024),
                  Color(0xFF120C18),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Column(
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
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppText(
                              'Wallet',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 3.1,
                            child: Image.asset(
                              'assets/Images/offer.png',
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (vm.isLoadingPackages)
                          const Center(
                            child: AppLoadingIndicator(color: Colors.white),
                          )
                        else if (vm.packagesError != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  vm.packagesError!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: vm.fetchPaymentStructure,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else if (vm.paymentPackages.isEmpty)
                          const Center(
                            child: Text(
                              'No packages available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                return GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _crossAxisCount(width),
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: _gridAspectRatio(
                                          width,
                                        ),
                                      ),
                                  itemCount: vm.paymentPackages.length,
                                  itemBuilder: (context, index) {
                                    final package = vm.paymentPackages[index];
                                    final amount = package.amount;
                                    final hasDiscount =
                                        package.offerStatus == 'true' &&
                                        package.offerAmount != '0';
                                    final displayPrice = hasDiscount
                                        ? int.tryParse(package.offerAmount) ??
                                              amount
                                        : amount;
                                    final originalPrice = hasDiscount
                                        ? amount
                                        : null;

                                    return _buildPackageCard(
                                      package: package,
                                      hasDiscount: hasDiscount,
                                      displayPrice: displayPrice,
                                      originalPrice: originalPrice,
                                      isProcessing: vm.isLoading,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    if (vm.isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.4),
                        child: const Center(
                          child: AppLoadingIndicator(color: Colors.white),
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
