// lib/StaffScreenScreens/staffChat/ViewModel/blocked_users_vm.dart

import 'package:bonding_app/BondingScreens/BlockedUsers/Model/blocked_users_list_model.dart';
import 'package:flutter/foundation.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';

class BlockedUsersListVm extends ChangeNotifier {
  final ChatRepository repo;
  BlockedUsersListVm({required this.repo});

  bool _loading = false;
  String? _error;
  BlockedListResponse? _response;

  bool get loading => _loading;
  String? get error => _error;
  List<BlockedItem> get users => _response?.data ?? [];
  int get count => _response?.count ?? users.length;

  Future<void> fetchBlockedUsers({
    required bool isStaff,

  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await repo.getBlockedUsers(isStaff: isStaff,  );
      _response = BlockedListResponse.fromJson(raw);
    } catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _loading = false;
    _error = null;
    _response = null;
    notifyListeners();
  }
}
