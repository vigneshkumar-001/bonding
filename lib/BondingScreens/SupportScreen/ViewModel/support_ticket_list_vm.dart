import 'package:bonding_app/BondingScreens/SupportScreen/Model/support_list_response.dart';
import 'package:flutter/material.dart';
import '../../PrivacyPolicy/Repository/settings_repository.dart';

class SupportTicketListVM extends ChangeNotifier {
  final SettingsRepository repo;
  SupportTicketListVM(this.repo);

  bool isLoading = false;
  String? errorMessage;

  List<SupportTicketItem> tickets = [];
  Pagination? pagination;

  Future<void> fetchTickets({int page = 1, int limit = 50,required bool isStaff }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await repo.getSupportTickets(page: page, limit: limit, isStaff: isStaff);
      tickets = res.data;
      pagination = res.pagination;
    } catch (e) {
      errorMessage = e.toString().replaceFirst("Exception: ", "");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchTickets(isStaff: false);
}
