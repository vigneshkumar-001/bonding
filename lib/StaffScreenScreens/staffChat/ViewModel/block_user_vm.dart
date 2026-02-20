import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/Model/block_user_model.dart';
import 'package:flutter/foundation.dart';

class BlockUserVM extends ChangeNotifier {
  final ChatRepository repo;

  BlockUserVM({required this.repo});

  bool _loading = false;
  String? _error;
  BlockUserResponse? _lastResponse;

  bool get loading => _loading;
  String? get error => _error;
  BlockUserResponse? get lastResponse => _lastResponse;

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

  Future<bool> blockUser({
    required String userId,
    required String staffId,
    required String reason,
    required bool isStaff,
  }) async {
    _error = null;
    _lastResponse = null;
    _setLoading(true);

    try {
      final respMap = await repo.blockUser(
        userId: userId,
        staffId: staffId,
        reason: reason.trim().isEmpty ? "No reason" : reason.trim(),
        isStaff: isStaff,
      );

      // ✅ Convert to model
      _lastResponse = BlockUserResponse.fromJson(respMap);

      // ✅ status check
      if (_lastResponse?.status != true) {
        _error = _lastResponse?.message ?? "Block failed";
        _setLoading(false);
        return false;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }
}
