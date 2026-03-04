// lib/Socket/socket_service.dart

import 'dart:async';

import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../BondingScreens/AuthService.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? _socket;

  IO.Socket get socket => _socket!;

  bool get isConnected => _socket?.connected == true;

  String? registeredStaffMongoId;

  String? _pendingStaffMemberId;

  final _staffListCtrl = StreamController<dynamic>.broadcast();

  final _receiveMessageCtrl = StreamController<dynamic>.broadcast();

  final _chatBlockedCtrl = StreamController<dynamic>.broadcast();

  final _chatErrorCtrl = StreamController<dynamic>.broadcast();

  final _statusChangedCtrl = StreamController<dynamic>.broadcast();

  final _connectionCtrl = StreamController<bool>.broadcast();

  final _registeredUserCtrl = StreamController<dynamic>.broadcast();

  final _registeredStaffCtrl = StreamController<dynamic>.broadcast();

  final _chatJoinedCtrl = StreamController<dynamic>.broadcast();

  Stream<dynamic> get staffListStream => _staffListCtrl.stream;

  Stream<dynamic> get receiveMessageStream => _receiveMessageCtrl.stream;

  Stream<dynamic> get chatBlockedStream => _chatBlockedCtrl.stream;

  Stream<dynamic> get chatErrorStream => _chatErrorCtrl.stream;

  Stream<dynamic> get staffStatusChangedStream => _statusChangedCtrl.stream;

  Stream<bool> get connectionStream => _connectionCtrl.stream;

  Stream<dynamic> get registeredUserStream => _registeredUserCtrl.stream;

  Stream<dynamic> get registeredStaffStream => _registeredStaffCtrl.stream;

  Stream<dynamic> get chatJoinedStream => _chatJoinedCtrl.stream;

  Timer? _reconnectTimer;

  int _attempt = 0;

  bool _manualDisconnect = false;

  String _baseUrl = "https://bnd.twoofus.tech";

  String? _lastRegisterEvent; // register_user / register_staff

  Future<void>? _connectInProgress;

  bool _registeredOk = false;

  String _normalizeBaseUrl(String? input) {
    final raw = (input ?? _baseUrl).trim();

    final uri = Uri.tryParse(raw);

    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return "https://bnd.twoofus.tech";
    }

    final hasValidPort = uri.hasPort && uri.port > 0;

    return Uri(
      scheme: uri.scheme,

      host: uri.host,

      port: hasValidPort ? uri.port : null,
    ).toString();
  }

  Future<String?> waitForRegisteredStaffMongoId({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (registeredStaffMongoId != null && registeredStaffMongoId!.isNotEmpty) {
      return registeredStaffMongoId;
    }

    final completer = Completer<String?>();

    StreamSubscription? sub;

    sub = registeredStaffStream.listen((data) {
      try {
        final m = (data is Map)
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};

        final sid = (m["staffId"] ?? "").toString();

        if (sid.isNotEmpty) {
          registeredStaffMongoId = sid;

          if (!completer.isCompleted) completer.complete(sid);

          sub?.cancel();
        }
      } catch (_) {}
    });

    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(registeredStaffMongoId);

        sub?.cancel();
      }
    });

    return completer.future;
  }

  Future<void> connectUserRegister({String? baseUrl}) async {
    _lastRegisterEvent = "register_user";

    _baseUrl = _normalizeBaseUrl(baseUrl);

    if (isConnected) {
      _registeredOk = false;

      socket.emit("register_user");

      return;
    }

    return _ensureConnectedAndRegistered();
  }

  Future<void> connectStaffRegister({String? baseUrl}) async {
    _lastRegisterEvent = "register_staff";

    _baseUrl = _normalizeBaseUrl(baseUrl);

    if (isConnected) {
      _registeredOk = false;

      socket.emit("register_staff");

      return;
    }

    return _ensureConnectedAndRegistered();
  }

  Future<void> connectStaff(String staffMemberId, {String? baseUrl}) async {
    _baseUrl = _normalizeBaseUrl(baseUrl);

    _pendingStaffMemberId = staffMemberId;

    _lastRegisterEvent = null;

    await _ensureConnected();

    if (isConnected && _pendingStaffMemberId != null) {
      socket.emit("staff_online", {"memberID": _pendingStaffMemberId});

      _pendingStaffMemberId = null;
    }
  }

  void listenStaffList(Function(dynamic) onUpdate) {
    _socket?.off("get_staff_list");

    _socket?.on("get_staff_list", (data) => onUpdate(data));
  }

  void removeStaffListListener() {
    _socket?.off("get_staff_list");
  }

  Future<void> joinChatSafe({
    required String staffId,

    required String userId,
  }) async {
    if (!isConnected) return;

    String fixedStaffId = staffId;

    if (staffId.startsWith("BON")) {
      final mongo = await waitForRegisteredStaffMongoId();

      if (mongo != null && mongo.isNotEmpty) fixedStaffId = mongo;
    }

    if (fixedStaffId.startsWith("BON")) {
      _chatErrorCtrl.add({"message": "Staff not registered yet. Retry join."});

      return;
    }

    socket.emit("join_chat", {"staffId": fixedStaffId, "userId": userId});
  }

  void joinChat({required String staffId, required String userId}) {
    if (!isConnected) return;

    socket.emit("join_chat", {"staffId": staffId, "userId": userId});
  }

  Future<void> sendMessageWithAck({
    required String staffId,

    required String userId,

    required String message,

    required Function(dynamic res) onAck,
  }) async {
    if (!isConnected) {
      onAck({"ok": false, "message": "socket not connected"});

      return;
    }

    String fixedStaffId = staffId;

    if (staffId.startsWith("BON")) {
      final mongo = await waitForRegisteredStaffMongoId();

      if (mongo != null && mongo.isNotEmpty) fixedStaffId = mongo;
    }

    if (fixedStaffId.startsWith("BON")) {
      onAck({"ok": false, "message": "Staff not registered yet"});

      return;
    }

    socket.emitWithAck("send_message", {
      "staffId": fixedStaffId,
      "userId": userId,
      "message": message,
    }, ack: (data) => onAck(data));
  }

  void sendMessage({
    required String staffId,

    required String userId,

    required String message,
  }) {
    if (!isConnected) return;

    socket.emit("send_message", {
      "staffId": staffId,

      "userId": userId,

      "message": message,
    });
  }

  void requestStaffList({
    String eventName = "get_staff_list",

    Map<String, dynamic> payload = const {},
  }) {
    if (!isConnected) return;

    socket.emit(eventName, payload);
  }

  Future<void> _ensureConnected() async {
    if (isConnected && _socket != null) return;

    if (_connectInProgress != null) {
      return _connectInProgress!;
    }

    _connectInProgress = _connectBase();

    try {
      await _connectInProgress!;
    } finally {
      _connectInProgress = null;
    }
  }

  Future<void> _ensureConnectedAndRegistered() async {
    if (isConnected && _registeredOk == true) return;

    await _ensureConnected();
  }

  Future<void> _connectBase() async {
    _manualDisconnect = false;

    _attempt = 0;

    _registeredOk = false;

    _reconnectTimer?.cancel();

    _baseUrl = _normalizeBaseUrl(_baseUrl);

    AppLogger.log.i("Socket URL => $_baseUrl");

    final raw = await AuthService.getToken();

    final t = (raw ?? "").trim();

    final bearer = t.isEmpty ? "" : (t.startsWith("Bearer ") ? t : "Bearer $t");

    if (bearer.isEmpty) {
      AppLogger.log.e("Socket token missing, skip connect");

      return;
    }

    _disposeSocketOnly();

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setPath('/socket.io')
          // iOS is more sensitive to polling timeouts via some proxies/CDNs.
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .disableReconnection() // using manual reconnect below
          .setTimeout(20000)
          .setAuth({"token": bearer})
          .setQuery({"token": bearer})
          .setExtraHeaders({"Authorization": bearer})
          .build(),
    );

    _attachListeners();

    _socket!.connect();
  }

  void _attachListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _attempt = 0;

      _connectionCtrl.add(true);

      AppLogger.log.i("Socket connected: ${_socket!.id}");

      if (_pendingStaffMemberId != null && _pendingStaffMemberId!.isNotEmpty) {
        _socket!.emit("staff_online", {"memberID": _pendingStaffMemberId});

        _pendingStaffMemberId = null;
      }

      if (_lastRegisterEvent == "register_user" ||
          _lastRegisterEvent == "register_staff") {
        _registeredOk = false;

        _socket!.emit(_lastRegisterEvent!);
      }
    });

    _socket!.onDisconnect((_) {
      _connectionCtrl.add(false);

      _registeredOk = false;

      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onConnectError((err) {
      _connectionCtrl.add(false);

      _registeredOk = false;

      _chatErrorCtrl.add(err);

      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onError((err) {
      _connectionCtrl.add(false);

      _registeredOk = false;

      _chatErrorCtrl.add(err);

      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.on("registered_user", (data) {
      _registeredOk = true;

      _registeredUserCtrl.add(data);
    });

    _socket!.on("registered_staff", (data) {
      _registeredOk = true;

      try {
        final m = Map<String, dynamic>.from(data);

        registeredStaffMongoId = (m["staffId"] ?? "").toString();
      } catch (_) {}

      _registeredStaffCtrl.add(data);
    });

    _socket!.on("chat_joined", (data) => _chatJoinedCtrl.add(data));

    _socket!.on("receive_message", (data) => _receiveMessageCtrl.add(data));

    _socket!.on("chat_error", (data) => _chatErrorCtrl.add(data));

    _socket!.on("chat_blocked", (data) => _chatBlockedCtrl.add(data));

    _socket!.on("staff_status_changed", (data) => _statusChangedCtrl.add(data));

    _socket!.on("get_staff_list", (data) => _staffListCtrl.add(data));
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_manualDisconnect) return;

    _attempt += 1;

    final pow = _attempt.clamp(0, 3);

    final delayMs = (1000 * (1 << pow)).clamp(1000, 10000);

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_manualDisconnect) return;

      if (isConnected) return;

      try {
        await _connectBase();
      } catch (e) {
        _chatErrorCtrl.add(e);

        _scheduleReconnect();
      }
    });
  }

  void reconnect() {
    if (isConnected) return;

    _scheduleReconnect();
  }

  void disconnect() {
    _manualDisconnect = true;

    _reconnectTimer?.cancel();

    _reconnectTimer = null;

    _registeredOk = false;

    _pendingStaffMemberId = null;

    _disposeSocketOnly();

    _connectionCtrl.add(false);
  }

  void _disposeSocketOnly() {
    try {
      _socket?.clearListeners();

      _socket?.disconnect();

      _socket?.dispose();
    } catch (_) {}

    _socket = null;
  }

  void disposeStreams() {
    _staffListCtrl.close();

    _receiveMessageCtrl.close();

    _chatBlockedCtrl.close();

    _chatErrorCtrl.close();

    _statusChangedCtrl.close();

    _connectionCtrl.close();

    _registeredUserCtrl.close();

    _registeredStaffCtrl.close();

    _chatJoinedCtrl.close();
  }
}

/*
// lib/Socket/socket_service.dart
import 'dart:async';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../BondingScreens/AuthService.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // ----------------------------
  // Socket
  // ----------------------------
  IO.Socket? _socket;
  IO.Socket get socket => _socket!;
  bool get isConnected => _socket?.connected == true;

  /// ✅ mongo staffId received from `registered_staff`
  String? registeredStaffMongoId;

  // ✅ runtime pending staff memberID (NO STORAGE)
  String? _pendingStaffMemberId;

  // ----------------------------
  // Streams (UI listeners)
  // ----------------------------
  final _staffListCtrl = StreamController<dynamic>.broadcast();
  final _receiveMessageCtrl = StreamController<dynamic>.broadcast();
  final _chatBlockedCtrl = StreamController<dynamic>.broadcast();
  final _chatErrorCtrl = StreamController<dynamic>.broadcast();
  final _statusChangedCtrl = StreamController<dynamic>.broadcast();
  final _connectionCtrl = StreamController<bool>.broadcast();

  final _registeredUserCtrl = StreamController<dynamic>.broadcast();
  final _registeredStaffCtrl = StreamController<dynamic>.broadcast();
  final _chatJoinedCtrl = StreamController<dynamic>.broadcast();

  Stream<dynamic> get staffListStream => _staffListCtrl.stream;
  Stream<dynamic> get receiveMessageStream => _receiveMessageCtrl.stream;
  Stream<dynamic> get chatBlockedStream => _chatBlockedCtrl.stream;
  Stream<dynamic> get chatErrorStream => _chatErrorCtrl.stream;
  Stream<dynamic> get staffStatusChangedStream => _statusChangedCtrl.stream;
  Stream<bool> get connectionStream => _connectionCtrl.stream;

  Stream<dynamic> get registeredUserStream => _registeredUserCtrl.stream;
  Stream<dynamic> get registeredStaffStream => _registeredStaffCtrl.stream;
  Stream<dynamic> get chatJoinedStream => _chatJoinedCtrl.stream;

  // ----------------------------
  // Reconnect backoff
  // ----------------------------
  Timer? _reconnectTimer;
  int _attempt = 0;
  bool _manualDisconnect = false;

  // remember last connect config
  String _baseUrl = "https://bnd.twoofus.tech";

  // ✅ Only these can be emitted without payload onConnect:
  String? _lastRegisterEvent; // register_user / register_staff

  // avoid duplicate connect
  Future<void>? _connectInProgress;

  // flip true when server sends registered_user/registered_staff
  bool _registeredOk = false;

  // ============================================================
  // ✅ WAIT UNTIL mongo staffId IS READY (IMPORTANT)
  // ============================================================
  Future<String?> waitForRegisteredStaffMongoId({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (registeredStaffMongoId != null && registeredStaffMongoId!.isNotEmpty) {
      return registeredStaffMongoId;
    }

    final completer = Completer<String?>();
    StreamSubscription? sub;

    sub = registeredStaffStream.listen((data) {
      try {
        final m = (data is Map)
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final sid = (m["staffId"] ?? "").toString();
        if (sid.isNotEmpty) {
          registeredStaffMongoId = sid;
          if (!completer.isCompleted) completer.complete(sid);
          sub?.cancel();
        }
      } catch (_) {}
    });

    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(registeredStaffMongoId);
        sub?.cancel();
      }
    });

    return completer.future;
  }

  // ============================================================
  // PUBLIC: Connect
  // ============================================================

  /// ✅ CHAT USER (register_user with NO payload)
  Future<void> connectUserRegister({String? baseUrl}) async {
    _lastRegisterEvent = "register_user";
    if (baseUrl != null) _baseUrl = baseUrl;

    if (isConnected) {
      _registeredOk = false;
      AppLogger.log.i("🟢 register_user emit (connected already)");
      socket.emit("register_user");
      return;
    }

    return _ensureConnectedAndRegistered();
  }

  /// ✅ CHAT STAFF (register_staff with NO payload)
  Future<void> connectStaffRegister({String? baseUrl}) async {
    _lastRegisterEvent = "register_staff";
    if (baseUrl != null) _baseUrl = baseUrl;

    if (isConnected) {
      _registeredOk = false;
      AppLogger.log.i("🟢 register_staff emit (connected already)");
      socket.emit("register_staff");
      return;
    }

    return _ensureConnectedAndRegistered();
  }

  /// ✅ staff_online MUST HAVE PAYLOAD (memberID)
  Future<void> connectStaff(String staffMemberId, {String? baseUrl}) async {
    if (baseUrl != null) _baseUrl = baseUrl;

    // ✅ Keep staff id pending until connected
    _pendingStaffMemberId = staffMemberId;

    // ❌ VERY IMPORTANT: staff_online should NOT be set as _lastRegisterEvent
    // Because onConnect would emit it with NO payload.
    _lastRegisterEvent = null;

    await _ensureConnected();

    // ✅ if already connected, emit immediately with payload
    if (isConnected && _pendingStaffMemberId != null) {
      socket.emit("staff_online", {"memberID": _pendingStaffMemberId});
      AppLogger.log.i("🟢 staff_online emitted → $_pendingStaffMemberId");
      _pendingStaffMemberId = null;
    }
  }

  void listenStaffList(Function(dynamic) onUpdate) {
    _socket?.off("get_staff_list");
    _socket?.on("get_staff_list", (data) => onUpdate(data));
  }

  void removeStaffListListener() {
    _socket?.off("get_staff_list");
  }

  // ============================================================
  // ✅ CHAT ACTIONS (FIXED)
  // ============================================================

  /// ✅ JOIN CHAT SAFELY
  Future<void> joinChatSafe({
    required String staffId,
    required String userId,
  }) async {
    if (!isConnected) return;

    String fixedStaffId = staffId;

    if (staffId.startsWith("BON")) {
      final mongo = await waitForRegisteredStaffMongoId();
      if (mongo != null && mongo.isNotEmpty) fixedStaffId = mongo;
    }

    if (fixedStaffId.startsWith("BON")) {
      AppLogger.log.e("⛔ join_chat blocked: staff mongo id not ready");
      _chatErrorCtrl.add({"message": "Staff not registered yet. Retry join."});
      return;
    }

    final payload = {"staffId": fixedStaffId, "userId": userId};
    AppLogger.log.i("💡 ➡️ join_chat emit: $payload");
    socket.emit("join_chat", payload);
  }

  @Deprecated("Use joinChatSafe()")
  void joinChat({required String staffId, required String userId}) {
    if (!isConnected) return;
    final payload = {"staffId": staffId, "userId": userId};
    socket.emit("join_chat", payload);
  }

  /// ✅ SEND MESSAGE WITH ACK SAFELY
  Future<void> sendMessageWithAck({
    required String staffId,
    required String userId,
    required String message,
    required Function(dynamic res) onAck,
  }) async {
    if (!isConnected) {
      onAck({"ok": false, "message": "socket not connected"});
      return;
    }

    String fixedStaffId = staffId;

    if (staffId.startsWith("BON")) {
      final mongo = await waitForRegisteredStaffMongoId();
      if (mongo != null && mongo.isNotEmpty) fixedStaffId = mongo;
    }

    if (fixedStaffId.startsWith("BON")) {
      onAck({"ok": false, "message": "Staff not registered yet"});
      return;
    }

    final payload = {
      "staffId": fixedStaffId,
      "userId": userId,
      "message": message,
    };
    AppLogger.log.i("💡 ➡️ send_message emit (ack): $payload");

    socket.emitWithAck(
      "send_message",
      payload,
      ack: (data) => onAck(data),
    );
  }

  void sendMessage({
    required String staffId,
    required String userId,
    required String message,
  }) {
    if (!isConnected) return;
    final payload = {"staffId": staffId, "userId": userId, "message": message};
    AppLogger.log.i("💡 ➡️ send_message emit: $payload");
    socket.emit("send_message", payload);
  }

  void requestStaffList({
    String eventName = "get_staff_list",
    Map<String, dynamic> payload = const {},
  }) {
    if (!isConnected) return;
    socket.emit(eventName, payload);
  }

  // ============================================================
  // CORE: ensure connected once
  // ============================================================
  Future<void> _ensureConnected() async {
    if (isConnected && _socket != null) return;

    if (_connectInProgress != null) {
      return _connectInProgress!;
    }

    _connectInProgress = _connectBase();
    try {
      await _connectInProgress!;
    } finally {
      _connectInProgress = null;
    }
  }

  Future<void> _ensureConnectedAndRegistered() async {
    if (isConnected && _registeredOk == true) return;
    await _ensureConnected();
  }

  // ============================================================
  // Socket connect base
  // ============================================================
  Future<void> _connectBase() async {
    _manualDisconnect = false;
    _attempt = 0;
    _registeredOk = false;

    _reconnectTimer?.cancel();

    final raw = await AuthService.getToken();
    final t = (raw ?? "").trim();
    final bearer = t.isEmpty ? "" : (t.startsWith("Bearer ") ? t : "Bearer $t");

    _disposeSocketOnly();

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(999999)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(8000)
          .setTimeout(12000)
          .setAuth({"token": bearer})
          .setExtraHeaders({"Authorization": bearer})
          .build(),
    );

    _attachListeners();
    _socket!.connect();
  }

  void _attachListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _attempt = 0;
      _connectionCtrl.add(true);
      AppLogger.log.i("✅ Socket connected: ${_socket!.id}");

      // ✅ 1) If staff pending → emit staff_online WITH payload
      if (_pendingStaffMemberId != null && _pendingStaffMemberId!.isNotEmpty) {
        _socket!.emit("staff_online", {"memberID": _pendingStaffMemberId});
        AppLogger.log.i(
            "🟢 staff_online emitted (onConnect) → $_pendingStaffMemberId");
        _pendingStaffMemberId = null;
      }

      // ✅ 2) ONLY register_user/register_staff can emit no payload
      if (_lastRegisterEvent == "register_user" ||
          _lastRegisterEvent == "register_staff") {
        _registeredOk = false;
        AppLogger.log.i("🟢 ${_lastRegisterEvent!} emit (no payload)");
        _socket!.emit(_lastRegisterEvent!);
      }
    });

    _socket!.onDisconnect((_) {
      _connectionCtrl.add(false);
      AppLogger.log.e("❌ Socket disconnected");
      _registeredOk = false;
      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onConnectError((err) {
      _connectionCtrl.add(false);
      _registeredOk = false;
      AppLogger.log.e("⚠ Socket connect error: $err");
      _chatErrorCtrl.add(err);
      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.onError((err) {
      _connectionCtrl.add(false);
      _registeredOk = false;
      AppLogger.log.e("⚠ Socket error: $err");
      _chatErrorCtrl.add(err);
      if (!_manualDisconnect) _scheduleReconnect();
    });

    _socket!.on("registered_user", (data) {
      _registeredOk = true;
      AppLogger.log.i("✅ registered_user: $data");
      _registeredUserCtrl.add(data);
    });

    _socket!.on("registered_staff", (data) {
      _registeredOk = true;
      AppLogger.log.i("✅ registered_staff: $data");

      try {
        final m = Map<String, dynamic>.from(data);
        registeredStaffMongoId = (m["staffId"] ?? "").toString();
      } catch (_) {}

      _registeredStaffCtrl.add(data);
    });

    _socket!.on("chat_joined", (data) {
      AppLogger.log.i("✅ chat_joined: $data");
      _chatJoinedCtrl.add(data);
    });

    _socket!.on("receive_message", (data) {
      AppLogger.log.i("✅ receive_message: $data");
      _receiveMessageCtrl.add(data);
    });

    _socket!.on("chat_error", (data) {
      AppLogger.log.e("⚠ chat_error: $data");
      _chatErrorCtrl.add(data);
    });

    _socket!.on("chat_blocked", (data) {
      AppLogger.log.e("⛔ chat_blocked: $data");
      _chatBlockedCtrl.add(data);
    });

    _socket!.on("staff_status_changed", (data) => _statusChangedCtrl.add(data));
    _socket!.on("get_staff_list", (data) => _staffListCtrl.add(data));
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_manualDisconnect) return;

    _attempt += 1;
    final pow = _attempt.clamp(0, 3);
    final delayMs = (1000 * (1 << pow)).clamp(1000, 10000);

    AppLogger.log.w("🔄 Reconnecting in ${delayMs}ms (attempt $_attempt)");

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_manualDisconnect) return;
      if (isConnected) return;
      try {
        await _connectBase();
      } catch (e) {
        _chatErrorCtrl.add(e);
        _scheduleReconnect();
      }
    });
  }

  void reconnect() {
    if (isConnected) return;
    _scheduleReconnect();
  }

  // ============================================================
  // Cleanup
  // ============================================================
  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _registeredOk = false;

    // optional: clear pending online
    _pendingStaffMemberId = null;

    _disposeSocketOnly();
    _connectionCtrl.add(false);
  }

  void _disposeSocketOnly() {
    try {
      _socket?.clearListeners();
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }

  void disposeStreams() {
    _staffListCtrl.close();
    _receiveMessageCtrl.close();
    _chatBlockedCtrl.close();
    _chatErrorCtrl.close();
    _statusChangedCtrl.close();
    _connectionCtrl.close();
    _registeredUserCtrl.close();
    _registeredStaffCtrl.close();
    _chatJoinedCtrl.close();
  }
}
*/
