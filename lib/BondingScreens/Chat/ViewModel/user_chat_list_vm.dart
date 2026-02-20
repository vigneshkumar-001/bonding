// lib/BondingScreens/Chat/ViewModel/user_chat_list_vm.dart
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../Repository/chat_repository.dart';
import '../Model/user_chat_list_model.dart';

class UserChatListVm extends ChangeNotifier {
  final ChatRepository repo;
  UserChatListVm({required this.repo});

  // -------------------- state --------------------
  bool loading = false;
  bool loadingMore = false;
  String? error;

  int page = 1;
  int limit = 12;
  bool hasMore = true;

  final List<UserChatListItem> _chats = [];
  List<UserChatListItem> get chats => List.unmodifiable(_chats);

  Pagination? pagination;

  // -------------------- init / refresh --------------------
  Future<void> init({int limit = 12}) async {
    this.limit = limit;
    await fetch(reset: true);
  }

  Future<void> refresh() => fetch(reset: true);

  // -------------------- fetch list --------------------
  Future<void> fetch({bool reset = false}) async {
    if (loading || loadingMore) return;

    if (reset) {
      page = 1;
      hasMore = true;
      error = null;
      _chats.clear();
      pagination = null;
      loading = true;
    } else {
      if (!hasMore) return;
      loadingMore = true;
    }
    notifyListeners();

    try {
      // ✅ You must have this in repository:
      // repo.getUserChatList({page, limit})
      final jsonBody = await repo.getUserChatList(page: page, limit: limit);

      final res = UserChatListResponse.fromJson(
        Map<String, dynamic>.from(jsonBody as Map),
      );
      AppLogger.log.i(jsonBody);
      AppLogger.log.i(res);
      if (!res.status) {
        throw Exception(res.message.isNotEmpty ? res.message : "Fetch failed");
      }

      // merge (unique by staffId)
      for (final item in res.data) {
        final idx = _chats.indexWhere((x) => x.staffId == item.staffId);
        if (idx == -1) {
          _chats.add(item);
        } else {
          // replace existing (latest lastMessage etc.)
          _chats[idx] = item;
        }
      }

      // sort by lastMessageAt desc
      _chats.sort((a, b) {
        final ad = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      pagination = res.pagination;

      final totalPages = res.pagination?.totalPages ?? 1;
      hasMore = page < totalPages;
      if (hasMore) page += 1;

      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint("❌ USER CHAT LIST ERROR: $error");
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  // -------------------- local updates --------------------
  void clearUnread(String staffId) {
    final idx = _chats.indexWhere((c) => c.staffId == staffId);
    if (idx == -1) return;

    _chats[idx] = _chats[idx].copyWith(unreadCount: 0);
    notifyListeners();
  }

  void updateLastMessage({
    required String staffId,
    required String message,
    required String senderRole,
    DateTime? at,
    int? unreadCount,
  }) {
    final idx = _chats.indexWhere((c) => c.staffId == staffId);
    if (idx == -1) return;

    _chats[idx] = _chats[idx].copyWith(
      lastMessage: message,
      lastSenderRole: senderRole,
      lastMessageAt: at ?? DateTime.now(),
      unreadCount: unreadCount ?? _chats[idx].unreadCount,
    );

    // keep sorted
    _chats.sort((a, b) {
      final ad = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    notifyListeners();
  }
}
