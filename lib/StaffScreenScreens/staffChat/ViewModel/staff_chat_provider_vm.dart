import 'dart:async';
import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:flutter/foundation.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';
import 'package:bonding_app/Socket/socket_service.dart';

class StaffChatProviderVm extends ChangeNotifier {
  final ChatRepository repo;
  final SocketService _socket = SocketService();

  StaffChatProviderVm({required this.repo});

  final List<ChatMessageModel> _messages = [];
  final Set<String> _seenIds = {}; // ✅ server _id dedupe
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);

  bool loading = false;
  bool loadingMore = false;
  String? error;

  int page = 1;
  int limit = 50;
  bool hasMore = true;

  StreamSubscription? _subRegistered;
  StreamSubscription? _subJoined;
  StreamSubscription? _subReceive;
  StreamSubscription? _subError;
  StreamSubscription? _subBlocked;

  bool _joined = false;

  String? _staffMongoId; // ✅ mongo staffId
  String? _userId;

  bool _listenersAttached = false;

  // ============================
  // ✅ INIT STAFF CHAT
  // ============================
  Future<void> initChat({
    required String staffId, // BON.. OR mongo (we will convert to mongo)
    required bool isStaff,
    required String userId,
  }) async {
    _userId = userId;

    // 1) connect staff socket
    await _socket.connectStaffRegister(baseUrl: ApiEndPoints().socketBaseUrl);

    // 2) wait for registered mongo id (most important)
    final mongo = await _socket.waitForRegisteredStaffMongoId();
    _staffMongoId = mongo ?? staffId;

    // 3) attach listeners once
    if (!_listenersAttached) {
      _attachSocketListeners();
      _listenersAttached = true;
    }

    // 4) preload history (API)
    await loadHistory(reset: true, isStaff: isStaff,userId: userId);

    // 5) join chat room
    if (_socket.isConnected && _staffMongoId != null && _userId != null) {
      _joined = false;
      _socket.joinChatSafe(staffId: _staffMongoId!, userId: _userId!);
    }
  }

  // ============================
  // ✅ API: Load history (same API)
  // ============================
  Future<void> loadHistory({bool reset = false, required bool isStaff,required String userId}) async {
    if (_staffMongoId == null) return;
    if (loading || loadingMore) return;

    if (reset) {
      page = 1;
      hasMore = true;
      _messages.clear();
      _seenIds.clear();
      error = null;
      loading = true;
    } else {
      if (!hasMore) return;
      loadingMore = true;
    }
    notifyListeners();

    try {
      final jsonBody = await repo.getChatHistory(
        isStaff: isStaff,
        staffId: userId,
        page: page,
        limit: limit,
      );

      if (jsonBody["status"] != true) {
        throw Exception(jsonBody["message"] ?? "History fetch failed");
      }

      final data = (jsonBody["data"] as List?) ?? [];
      final pagination = (jsonBody["pagination"] as Map?) ?? {};

      for (final item in data) {
        final m = ChatMessageModel.fromJson(Map<String, dynamic>.from(item));
        if (m.id.isEmpty) continue;
        if (_seenIds.contains(m.id)) continue;

        // ✅ only messages of this user chat
        if (_userId != null && (m.userId ?? "") != _userId) continue;

        _seenIds.add(m.id);
        _messages.add(m);
      }

      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final totalPages =
          int.tryParse((pagination["totalPages"] ?? "1").toString()) ?? 1;

      hasMore = page < totalPages;
      if (hasMore) page += 1;

      error = null;
    } catch (e) {
      error = e.toString();
      debugPrint("❌ STAFF HISTORY ERROR: $error");
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  // ============================
  // ✅ SEND MESSAGE (staff)
  // ============================
  void sendMessage(String text) {
    if (_staffMongoId == null || _userId == null) return;

    final msg = text.trim();
    if (msg.isEmpty) return;

    final tempId = "tmp_${DateTime.now().microsecondsSinceEpoch}";

    // ✅ local pending bubble
    final local = ChatMessageModel(
      id: tempId,
      staffId: _staffMongoId,
      userId: _userId,
      senderRole: "staff",
      message: msg,
      createdAt: DateTime.now(),
      isLocal: true,
      status: ChatMsgStatus.sending,
    );

    _messages.add(local);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    // socket not ready -> fail
    if (!_socket.isConnected || !_joined) {
      _markLocalStatus(tempId, ChatMsgStatus.failed);
      _socket.reconnect();
      return;
    }

    _socket.sendMessage(
      staffId: _staffMongoId!,
      userId: _userId!,
      message: msg,
    );
  }

  void retrySend(ChatMessageModel m) {
    if (m.message == null || m.message!.trim().isEmpty) return;

    _markLocalStatus(m.id, ChatMsgStatus.sending);

    if (!_socket.isConnected || !_joined) {
      _markLocalStatus(m.id, ChatMsgStatus.failed);
      _socket.reconnect();
      return;
    }

    _socket.sendMessage(
      staffId: _staffMongoId!,
      userId: _userId!,
      message: m.message!.trim(),
    );
  }

  void _markLocalStatus(String id, ChatMsgStatus status) {
    final idx = _messages.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(status: status);
    notifyListeners();
  }

  // ============================
  // ✅ SOCKET LISTENERS (staff)
  // ============================
  void _attachSocketListeners() {
    // when registered_staff -> join
    _subRegistered ??= _socket.registeredStaffStream.listen((_) {
      if (_staffMongoId == null || _userId == null) return;
      _joined = false;
      _socket.joinChatSafe(staffId: _staffMongoId!, userId: _userId!);
    });

    _subJoined ??= _socket.chatJoinedStream.listen((data) {
      final m = (data is Map) ? Map<String, dynamic>.from(data) : {};
      final staffId = (m["staffId"] ?? "").toString();
      final userId = (m["userId"] ?? "").toString();

      if (staffId == _staffMongoId && userId == _userId) {
        _joined = true;
        notifyListeners();
      }
    });

    _subReceive ??= _socket.receiveMessageStream.listen((data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);

      final staffId = (m["staffId"] ?? "").toString();
      final userId = (m["userId"] ?? "").toString();

      // ✅ filter only this room
      if (staffId != _staffMongoId || userId != _userId) return;

      final msg = ChatMessageModel.fromSocket(m);

      // ✅ dedupe by server _id
      if (msg.id.isNotEmpty && _seenIds.contains(msg.id)) return;
      if (msg.id.isNotEmpty) _seenIds.add(msg.id);

      // ✅ if this is my staff echo -> replace last local sending staff bubble
      final isMine = (msg.senderRole ?? "").toLowerCase() == "staff";
      if (isMine) {
        final idx = _messages.lastIndexWhere(
          (x) =>
              x.isLocal == true &&
              (x.senderRole ?? "").toLowerCase() == "staff" &&
              (x.message ?? "") == (msg.message ?? ""),
        );

        if (idx != -1) {
          _messages[idx] = msg.copyWith(
            status: ChatMsgStatus.sent,
            isLocal: false,
          );
          notifyListeners();
          return;
        }
      }

      _messages.add(msg);
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    });

    _subError ??= _socket.chatErrorStream.listen((e) {
      error = e.toString();
      notifyListeners();
    });

    _subBlocked ??= _socket.chatBlockedStream.listen((_) {
      error = "Chat blocked";
      notifyListeners();
    });
  }

  bool get isJoined => _joined;
  bool get isSocketConnected => _socket.isConnected;

  @override
  void dispose() {
    _subRegistered?.cancel();
    _subJoined?.cancel();
    _subReceive?.cancel();
    _subError?.cancel();
    _subBlocked?.cancel();
    super.dispose();
  }
}
