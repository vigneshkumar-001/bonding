


import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/Model/delete_account_model.dart';
import 'package:flutter/foundation.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';




class DeleteAccountVM extends ChangeNotifier {
  final ChatRepository repo;
  DeleteAccountVM({required this.repo});

  bool _loading = false;
  String? _error;
  DeleteAccountResponse? _last;

  bool get loading => _loading;
  String? get error => _error;
  DeleteAccountResponse? get lastResponse => _last;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clear() {
    _loading = false;
    _error = null;
    _last = null;
    notifyListeners();
  }

  Future<bool> submitDeleteAccount({
    required List<String> reasonCodes,
    required bool isStaff,
  }) async {
    _error = null;
    _last = null;

    if (reasonCodes.isEmpty) {
      _error = "Please select at least one reason";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final json = await repo.deleteAccount(reasonCodes: reasonCodes,isStaff:isStaff );
      final model = DeleteAccountResponse.fromJson(json);

      if (model.status != true) {
        throw Exception(model.message.isNotEmpty ? model.message : "Delete failed");
      }

      _last = model;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
      _setLoading(false);
      return false;
    }
  }
}
