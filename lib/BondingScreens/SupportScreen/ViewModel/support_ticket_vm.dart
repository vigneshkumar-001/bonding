import 'package:flutter/material.dart';

import '../../PrivacyPolicy/Repository/settings_repository.dart';
import '../Model/support_create_ticket_response.dart';

class SupportTicketVM extends ChangeNotifier {
  final SettingsRepository repo;
  SupportTicketVM(this.repo);

  bool isLoading = false;
  String? errorMessage;

  SupportTicketCreateResponse? _response;
  SupportTicketCreateResponse? get response => _response;

  String? get ticketId => _response?.data?.id;

  Future<bool> createTicket({
    required String title,
    required bool isStaff,
    required String description,
    String? message,
    List<String> mediaUrls = const [],
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await repo.postCreateTicket(
        isStaff: isStaff,
        title: title,
        description: description,
        message: message ?? description,
        media: mediaUrls,
      );

      _response = res;

      if (res.status == true && res.data != null) {
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = res.message;
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst("Exception: ", "");
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return false;
  }
}
