import 'dart:async';
import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:flutter/foundation.dart';

class ChatProviderVm extends ChangeNotifier {
  final ChatRepository repo;
  final SocketService _socket = SocketService();

  ChatProviderVm({required this.repo});

  final List<ChatMessageModel> _messages = [];
  final Set<String> _seenIds = {}; // server _id dedupe
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

  String? _staffId;
  String? _userId;

  bool _listenersAttached = false;

  // ============================
  // ✅ INIT
  // ============================
  Future<void> initChat({
    required String staffId,
    required bool isStaff,
    required String userId,
  }) async {
    _staffId = staffId;
    _userId = userId;

    await loadHistory(reset: true, isStaff: isStaff);

    await _socket.connectUserRegister();

    // ✅ if already registered, join immediately
    if (_socket.isConnected) {
      _socket.joinChat(staffId: _staffId!, userId: _userId!);
    }

    if (!_listenersAttached) {
      _attachSocketListeners();
      _listenersAttached = true;
    }
  }

  // ============================
  // ✅ API: Load history
  // ============================
  Future<void> loadHistory({bool reset = false, required bool isStaff}) async {
    if (_staffId == null) return;
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
        staffId: _staffId!,
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
      debugPrint("❌ HISTORY ERROR: $error");
    } finally {
      loading = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  // ============================
  // ✅ Send message (local add + socket send)
  // ============================
  void sendMessage(String text) {
    if (_staffId == null || _userId == null) return;

    final msg = text.trim();
    if (msg.isEmpty) return;

    // ✅ add local pending bubble immediately
    final tempId = "tmp_${DateTime.now().microsecondsSinceEpoch}";
    final local = ChatMessageModel(
      id: tempId,
      staffId: _staffId,
      userId: _userId,
      senderRole: "user",
      message: msg,
      createdAt: DateTime.now(),
      isLocal: true,
      status: ChatMsgStatus.sending,
    );

    _messages.add(local);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    debugPrint("📤 SEND(local added): $msg tempId=$tempId");

    // socket not ready -> mark failed
    if (!_socket.isConnected || !_joined) {
      debugPrint("⚠️ socket not connected/joined -> failed tempId=$tempId");
      _markLocalStatus(tempId, ChatMsgStatus.failed);
      _socket.reconnect(); // try reconnect
      return;
    }

    // send to backend
    _socket.sendMessage(staffId: _staffId!, userId: _userId!, message: msg);
    debugPrint("📡 SEND(socket emitted): $msg");

  }

  void retrySend(ChatMessageModel m) {
    if (m.message == null || m.message!.trim().isEmpty) return;

    // mark sending again
    _markLocalStatus(m.id, ChatMsgStatus.sending);

    if (!_socket.isConnected || !_joined) {
      debugPrint("⚠️ retry but socket not ready -> failed");
      _markLocalStatus(m.id, ChatMsgStatus.failed);
      _socket.reconnect();
      return;
    }

    _socket.sendMessage(
      staffId: _staffId!,
      userId: _userId!,
      message: m.message!.trim(),
    );
    debugPrint("🔁 RETRY(socket emitted): ${m.message}");
  }

  void _markLocalStatus(String id, ChatMsgStatus status) {
    final idx = _messages.indexWhere((x) => x.id == id);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(status: status);
    notifyListeners();
  }

  // ============================
  // ✅ Socket listeners
  // ============================
  void _attachSocketListeners() {
    _subRegistered ??= _socket.registeredUserStream.listen((_) {
      if (_staffId == null || _userId == null) return;
      _joined = false;
      _socket.joinChat(staffId: _staffId!, userId: _userId!);
    });

    _subJoined ??= _socket.chatJoinedStream.listen((data) {
      final m = (data is Map) ? Map<String, dynamic>.from(data) : {};
      final staffId = (m["staffId"] ?? "").toString();
      final userId = (m["userId"] ?? "").toString();

      if (staffId == _staffId && userId == _userId) {
        _joined = true;
        debugPrint("✅ SOCKET JOINED room staff=$staffId user=$userId");
        notifyListeners();
      }
    });

    _subReceive ??= _socket.receiveMessageStream.listen((data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);

      final staffId = (m["staffId"] ?? "").toString();
      final userId = (m["userId"] ?? "").toString();
      if (staffId != _staffId || userId != _userId) return;

      final msg = ChatMessageModel.fromSocket(m);

      // ✅ dedupe by server _id
      if (msg.id.isNotEmpty && _seenIds.contains(msg.id)) return;
      if (msg.id.isNotEmpty) _seenIds.add(msg.id);

      // ✅ if it is my message echo, replace local pending with server id
      final isMine = (msg.senderRole ?? "").toLowerCase() == "user";
      if (isMine) {
        final idx = _messages.lastIndexWhere(
          (x) =>
              x.isLocal == true &&
              (x.senderRole ?? "").toLowerCase() == "user" &&
              (x.message ?? "") == (msg.message ?? ""),
        );

        if (idx != -1) {
          _messages[idx] = msg.copyWith(
            status: ChatMsgStatus.sent,
            isLocal: false,
          );
          debugPrint("✅ LOCAL REPLACED with server msgId=${msg.id}");
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
      debugPrint("❌ SOCKET ERROR: $error");
      notifyListeners();
    });

    _subBlocked ??= _socket.chatBlockedStream.listen((_) {
      error = "Chat blocked by staff";
      debugPrint("⛔ BLOCKED");
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
