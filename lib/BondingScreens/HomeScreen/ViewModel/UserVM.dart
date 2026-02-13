// lib/BondingScreens/HomeScreen/ViewModel/UserVM.dart

import 'dart:convert';

import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepo;

  UserViewModel(this._userRepo);

  // ─── State ──────────────────────────────────────────────────────────────
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Fetch user details ─────────────────────────────────────────────────
  Future<void> fetchUserDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepo.getUserDetails();
      _currentUser = response.data;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("User fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update coin balance (API + local) ──────────────────────────────────
  Future<void> updateUserCoinBalance(int newBalance, String staffId, dynamic staffAmount, String callDuration , String callType) async {
    try {
      _isLoading = true;
      notifyListeners(); // ← already here, good

      final response = await _userRepo.updateCoinBalance(
        newCoinBalance: newBalance,
        staffId: staffId,
        staffAmount: staffAmount, callDuration: callDuration, callType: callType,
      );

      print("staus${response.status}");
      print("staus${response.data}");

      if (response.status && response.data != null) {
        // // Update local model
        // _currentUser = _currentUser?.copyWith(
        //   coinBalance: response.data!.coinBalance,
        // );

        // IMPORTANT: Notify UI that user data changed!
        notifyListeners();
        // updateLocalCoinBalance(response.data!.coinBalance);
        Utils.snackBar("Balance updated successfully");
      } else {
        print("??>>${response.message}");
        Utils.snackBarErrorMessage(response.message);
      }
    } catch (e) {
      print("Failed to update balance: $e");
      Utils.snackBarErrorMessage("Failed to update balance: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // ← safe to call again
    }
  }

  bool _isZimConnected = false;
  bool get isZimConnected => _isZimConnected;

  // Call this once when user logs in or app starts
  Future<void> initializeZimConnection(BuildContext context) async {
    if (_isZimConnected) return;

    final currentUser = _currentUser;
    if (currentUser == null || currentUser.memberID.isEmpty) return;

    final connected = await ZimConnectionService.ensureConnected(
      context,
      userId: currentUser.memberID,
      userName: currentUser.name ?? "User",
      avatarUrl: currentUser.image ?? "",
    );

    _isZimConnected = connected;
    notifyListeners();
  }

  void updateLocalCoinBalance(int newBalance) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(coinBalance: newBalance);
      notifyListeners();
    }
  }
  // Optional: Clear user data (e.g. on logout)
  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Optional: Refresh
  Future<void> refreshUser() => fetchUserDetails();


  Future<bool> updateUserProfile({
    String? name,
    String? bio,
    String? language,
    String? image,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final body = {
        if (name != null && name.isNotEmpty) "name": name,
        if (bio != null && bio.isNotEmpty) "bio": bio,
        if (language != null && language.isNotEmpty) "language": language,
        if (image != null && image.isNotEmpty) "image": image,
      };

      if (body.isEmpty) {
        return false; // Nothing to update
      }

      final response = await http.post(
        Uri.parse('${ApiEndPoints().baseUrl}auth/user/editProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          _currentUser = UserProfile.fromJson(json['data']);
          notifyListeners();
          return true;
        }
      }

      throw Exception("Update failed: ${response.body}");
    } catch (e) {
      debugPrint("Update profile error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}