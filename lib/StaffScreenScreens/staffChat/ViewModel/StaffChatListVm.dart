import 'package:flutter/foundation.dart';

import '../Model/staff_chat_list_item.dart';
import '../Repository/staff_repository.dart';

class StaffChatListVm extends ChangeNotifier {
  final StaffChatRepository repo;
  StaffChatListVm({required this.repo});

  final List<StaffChatItem> _chats = [];
  List<StaffChatItem> get chats => List.unmodifiable(_chats);

  bool isLoading = false;
  String? errorMessage;

  int page = 1;
  int limit = 12;
  bool hasMore = true;

  String? staffId;

  Future<void> connect({required String baseUrl, required String staffId}) async {
    this.staffId = staffId;
    await fetchChatList(reset: true);
  }

  Future<void> fetchChatList({bool reset = false}) async {
    if (isLoading) return;

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      if (reset) {
        page = 1;
        hasMore = true;
        _chats.clear();
      }

      final json = await repo.getStaffChatList(page: page, limit: limit);

      if (json["status"] != true) {
        throw Exception(json["message"] ?? "Chat list fetch failed");
      }

      final res = StaffChatListResponse.fromJson(
        Map<String, dynamic>.from(json),
      );

      _chats.addAll(res.data);

      // latest first
      _chats.sort((a, b) {
        final ad = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      hasMore = page < res.pagination.totalPages;
      if (hasMore) page++;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearUnread(String userId) {
    final idx = _chats.indexWhere((e) => e.userId == userId);
    if (idx == -1) return;

    _chats[idx] = _chats[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void updateFromSocket({
    required String userId,
    required String message,
    required String senderRole,
    DateTime? at,
  }) {
    final idx = _chats.indexWhere((e) => e.userId == userId);
    if (idx == -1) return;

    final old = _chats[idx];

    final updatedItem = old.copyWith(
      lastMessage: message,
      lastMessageAt: at ?? DateTime.now(),
      lastSenderRole: senderRole,
      unreadCount: old.unreadCount + 1,
    );

    _chats.removeAt(idx);
    _chats.insert(0, updatedItem);

    notifyListeners();
  }
}
