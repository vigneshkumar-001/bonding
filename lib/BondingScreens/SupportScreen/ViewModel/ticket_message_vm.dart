import 'package:flutter/material.dart';
import '../../PrivacyPolicy/Repository/settings_repository.dart';

class TicketMessageVM extends ChangeNotifier {
  final SettingsRepository repo;
  TicketMessageVM(this.repo);

  String? errorMessage;

  Future<bool> sendMessage({
    required String ticketId,
    required String message,
    required bool isStaff,
    List<String> mediaUrls = const [],
  }) async {
    errorMessage = null;

    try {
      final res = await repo.postAddTicketMessage(
        ticketId: ticketId,
        isStaff: isStaff,
        message: message,
        media: mediaUrls,
      );

      return res.status == true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst("Exception: ", "");
      return false;
    }
  }
}
