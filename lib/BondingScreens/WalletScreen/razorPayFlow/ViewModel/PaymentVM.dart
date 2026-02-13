// lib/viewmodels/wallet_view_model.dart

import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/PaymentModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/BankDetailModel.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/WithdrawHistoryModel.dart';
import 'package:flutter/material.dart';


class WalletViewModel extends ChangeNotifier {
  final WalletRepository _walletRepo;

  bool _isLoading = false;
  String? _errorMessage;
  PlaceOrderData? _lastPlacedOrder;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PlaceOrderData? get lastPlacedOrder => _lastPlacedOrder;

  WalletViewModel(this._walletRepo);

  Future<PlaceOrderResponse?> placeCoinOrder({
    required int amountInRupees,
    required String currency, required coins,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _walletRepo.placeOrder(
        amountInPaise: amountInRupees ,
        currency: currency,
        coin: coins

      );

      if (response.status && response.data != null) {
        _lastPlacedOrder = response.data;
        Utils.snackBar("Order placed successfully! Proceeding to payment...");
        notifyListeners();
        return response;
      } else {
        _errorMessage = response.message;
        Utils.snackBarErrorMessage(response.message);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      Utils.snackBarErrorMessage("Failed to place order: $e");
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPaymentAndCreditCoins({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _walletRepo.confirmPurchase(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (response.status && response.data != null) {
        Utils.snackBar("Payment verified! ${response.data!.creditedCoins} coins credited.");
        notifyListeners();
        return true;
      } else {
        print("/////${response.message}");
        Utils.snackBar(response.message);
        notifyListeners();
        return false;
      }
    } catch (e) {
      Utils.snackBarErrorMessage("Payment verification failed: $e");
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBankOrUpiDetails({
    String? accountNumber,
    String? ifsc,
    String? bankHolderName,
    String? bankName,
    String? upi,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final body = <String, dynamic>{};

      if (upi != null && upi.isNotEmpty) {
        body["UPI"] = upi;
      } else {
        if (accountNumber != null) body["accountNumber"] = accountNumber;
        if (ifsc != null) body["IFSC"] = ifsc;
        if (bankHolderName != null) body["bankHolderName"] = bankHolderName;
        if (bankName != null) body["bankNamee"] = bankName;
      }

      final response = await _walletRepo.addBankDetails(body: body);

      if (response.status && response.data != null) {
        Utils.snackBar("Bank/UPI details added successfully!");
        // Optionally update local user profile or navigate back
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        Utils.snackBarErrorMessage(response.message);
      }
    } catch (e) {
      _errorMessage = e.toString();
      Utils.snackBarErrorMessage("Failed to add details: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<BankDetailItem> _bankDetails = [];
  bool _isFetchingBankDetails = false;
  String? _bankError;

  List<BankDetailItem> get bankDetails => _bankDetails;
  bool get isFetchingBankDetails => _isFetchingBankDetails;
  String? get bankError => _bankError;

  Future<void> fetchBankDetails() async {
    _isFetchingBankDetails = true;
    _bankError = null;
    notifyListeners();

    try {
      final response = await _walletRepo.getAllBankDetails();
      _bankDetails = response.data ?? [];
    } catch (e) {
      _bankError = e.toString();
    } finally {
      _isFetchingBankDetails = false;
      notifyListeners();
    }
  }

  Future<void> deleteBankDetail(String bankId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _walletRepo.deleteBankDetails(bankId: bankId);

      Utils.snackBar("Bank/UPI detail deleted successfully");

      // Refresh list
      await fetchBankDetails();
    } catch (e) {
      Utils.snackBarErrorMessage("Failed to delete: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitStaffWithdrawal({
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifsc,
    required String bankHolderName,
    required String bankName,
    required String upi,
    required String confirmUpi,
    required int amount,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _walletRepo.staffWithdraw(
        accountNumber: accountNumber,
        confirmAccountNumber: confirmAccountNumber,
        ifsc: ifsc,
        bankHolderName: bankHolderName,
        bankName: bankName,
        upi: upi,
        confirmUpi: confirmUpi,
        amount: amount,
      );

      if (response.status && response.data != null) {
        // Success
        Utils.snackBar(
          "Withdrawal request of ₹$amount submitted successfully!\n"
              "It will be processed within 24-48 hours.",
        );

        // Clear field & go back
        // _amountController.clear();
        Navigator.pop(context);
      } else {
        // API returned status: false → show exact message
        final msg = response.message ?? "Withdrawal request failed";

        if (msg.toLowerCase().contains("insufficient") || msg.toLowerCase().contains("pending balance")) {
          Utils.snackBarErrorMessage(
              response.message
          );
        } else {
          Utils.snackBarErrorMessage(msg); // Show exact API message
        }
      }
    } catch (e) {
      // Network / parsing errors
      Utils.snackBarErrorMessage(
        "Something went wrong\n"
            "Please check your connection and try again.",
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<StaffWithdrawHistoryItem> _withdrawHistory = [];
  bool _isLoadingWithdraw = false;
  String? _withdrawError;

  List<StaffWithdrawHistoryItem> get withdrawHistory => _withdrawHistory;
  bool get isLoadingWithdraw => _isLoadingWithdraw;
  String? get withdrawError => _withdrawError;

  Future<void> fetchStaffWithdrawHistory() async {
    _isLoadingWithdraw = true;
    _withdrawError = null;
    notifyListeners();

    try {
      final response = await _walletRepo.getStaffWithdrawHistory();
      _withdrawHistory = response.data ?? [];
    } catch (e) {
      _withdrawError = e.toString();
    } finally {
      _isLoadingWithdraw = false;
      notifyListeners();
    }
  }

  Future<void> refreshWithdrawHistory() => fetchStaffWithdrawHistory();

  List<PaymentPackage> _paymentPackages = [];
  bool _isLoadingPackages = false;
  String? _packagesError;

  List<PaymentPackage> get paymentPackages => _paymentPackages;
  bool get isLoadingPackages => _isLoadingPackages;
  String? get packagesError => _packagesError;

  Future<void> fetchPaymentStructure() async {
    _isLoadingPackages = true;
    _packagesError = null;
    notifyListeners();

    try {
      final response = await _walletRepo.getPaymentStructure();
      _paymentPackages = response.data;
    } catch (e) {
      _packagesError = e.toString();
    } finally {
      _isLoadingPackages = false;
      notifyListeners();
    }
  }


}