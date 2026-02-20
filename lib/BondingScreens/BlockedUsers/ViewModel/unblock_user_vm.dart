import 'package:bonding_app/BondingScreens/BlockedUsers/Model/unblock_user_model.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';

import 'package:flutter/foundation.dart';

class UnblockUserVM extends ChangeNotifier {
  final ChatRepository repo;

  UnblockUserVM({required this.repo});

  bool _loading = false;
  String? _error;
  UnblockUserResponse? _lastResponse;

  bool get loading => _loading;
  String? get error => _error;
  UnblockUserResponse? get lastResponse => _lastResponse;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clear() {
    _loading = false;
    _error = null;
    _lastResponse = null;
    notifyListeners();
  }

  Future<bool> unblockUser({
    required String userId,
    bool isStaff = true,
  }) async {
    _error = null;
    _lastResponse = null;
    _setLoading(true);

    try {
      final resp = await repo.unblockUser(userId: userId, isStaff: isStaff);

      _lastResponse = UnblockUserResponse.fromJson(resp);

      _setLoading(false);

      // ✅ success check
      return _lastResponse?.status == true;
    } catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }
}
