// lib/BondingScreens/HomeScreen/ViewModel/UserVM.dart

import 'package:flutter/foundation.dart';

import 'package:bonding_app/BondingScreens/HistoryCard/Model/user_call_history_model.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/UserDataRepo.dart';

class UserCallHistoryVm extends ChangeNotifier {
  final UserRepository _userRepo;

  UserCallHistoryVm(this._userRepo);

  // ─── State ──────────────────────────────────────────────────────────────
  UserCallHistoryResponse? _userCallHistoryResponse;
  bool _isLoading = false;
  String? _errorMessage;

  /// ✅ getters
  UserCallHistoryResponse? get userCallHistoryResponse =>
      _userCallHistoryResponse;
  List<UserCallHistoryItem> get history =>
      _userCallHistoryResponse?.data ?? const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Fetch call history ────────────────────────────────────────────────
  Future<void> fetchUserCallHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepo.getUserCallHistory();

      /// ✅ store response correctly
      _userCallHistoryResponse = response;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("User call history fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// optional: clear history
  void clear() {
    _userCallHistoryResponse = null;
    _errorMessage = null;
    notifyListeners();
  }
}
