// lib/BondingScreens/DeleteAccount/ViewModel/delete_account_reasons_vm.dart

import 'package:bonding_app/BondingScreens/DeleteAccountScreeen/Model/delete_account_reasons_model.dart';
import 'package:flutter/foundation.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';


class DeleteAccountReasonsVM extends ChangeNotifier {
  final ChatRepository repo;
  DeleteAccountReasonsVM({required this.repo});

  bool _loading = false;
  String? _error;

  List<DeleteReasonOption> _reasons = [];
  List<DeleteReasonOption> get reasons => List.unmodifiable(_reasons);

  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clear() {
    _loading = false;
    _error = null;
    _reasons = [];
    notifyListeners();
  }

  Future<void> fetchReasons({required bool isStaff}) async {
    _error = null;
    _setLoading(true);

    try {
      final json = await repo.getDeleteAccountReasons(isStaff: isStaff);
      final model = DeleteAccountReasonsResponse.fromJson(json);

      if (model.status != true) {
        throw Exception(model.message.isNotEmpty ? model.message : "Fetch failed");
      }

      _reasons = model.data;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
      _reasons = [];
    } finally {
      _setLoading(false);
    }
  }
}
