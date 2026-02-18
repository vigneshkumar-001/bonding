import 'package:flutter/material.dart';
import '../../PrivacyPolicy/Repository/settings_repository.dart';
import '../Model/ticket_message_history_response.dart';

class TicketHistoryVM extends ChangeNotifier {
  final SettingsRepository repo;
  TicketHistoryVM(this.repo);

  bool isLoading = false;
  String? errorMessage;

  List<TicketHistoryMessage> messages = [];

  String? _activeTicketId;
  int _reqNo = 0; // ✅ increments for every call

  String? get activeTicketId => _activeTicketId;

  /// Call this when opening a new chat scre en
  void setActiveTicket(String ticketId) {
    if (_activeTicketId == ticketId) return;

    _activeTicketId = ticketId;

    // ✅ Clear old messages instantly so old ticket doesn't show
    messages = [];
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(
    String ticketId, {
    bool showLoader = true,
    required bool isStaff,
    bool clearBeforeFetch = false,
  }) async {
    // ✅ set active ticket always
    if (_activeTicketId != ticketId) {
      setActiveTicket(ticketId);
    } else if (clearBeforeFetch) {
      messages = [];
      notifyListeners();
    }

    final int myReq = ++_reqNo; // capture this request id

    if (showLoader) {
      isLoading = true;
      notifyListeners();
    }

    errorMessage = null;

    try {
      final res = await repo.getTicketHistory(ticketId,isStaff:isStaff );

      // ✅ If another request started after this one, ignore this response
      if (myReq != _reqNo) return;

      // ✅ If user switched ticket while request running, ignore
      if (_activeTicketId != ticketId) return;

      final newList = res.data?.messages ?? [];

      // ✅ Sort old -> new
      newList.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

      messages = newList;
    } catch (e) {
      if (myReq != _reqNo) return;
      if (_activeTicketId != ticketId) return;

      errorMessage = e.toString().replaceFirst("Exception: ", "");
    } finally {
      if (myReq != _reqNo) return;
      if (_activeTicketId != ticketId) return;

      if (showLoader) isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String ticketId,{required bool isStaff}) =>
      fetchHistory(ticketId, showLoader: true, clearBeforeFetch: true,isStaff: isStaff);

  Future<void> silentRefresh(String ticketId,{required bool isStaff}) =>
      fetchHistory(ticketId, showLoader: false, clearBeforeFetch: false,isStaff: isStaff);
}
