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
  String _baseUrl = "https://bondinig-ca63248fdb11.herokuapp.com";
  String? _lastRegisterEvent; // register_user / register_staff / staff_online

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

  /// ✅ OLD: staff_online (only if old backend supports)
  Future<void> connectStaff(String staffMemberId, {String? baseUrl}) async {
    _lastRegisterEvent = "staff_online";
    if (baseUrl != null) _baseUrl = baseUrl;

    await _ensureConnected(); // connect only

    if (isConnected) {
      socket.emit("staff_online", {"memberID": staffMemberId});
      AppLogger.log.i("🟢 staff_online emitted → $staffMemberId");
    }
  }

  void listenStaffList(Function(dynamic) onUpdate) {
    _socket?.on("get_staff_list", (data) => onUpdate(data));
  }

  // ============================================================
  // ✅ CHAT ACTIONS (FIXED)
  // ============================================================

  /// ✅ JOIN CHAT SAFELY
  /// If staffId is memberID (BON...), it will WAIT mongo id and use it.
  Future<void> joinChatSafe({required String staffId, required String userId}) async {
    if (!isConnected) return;

    String fixedStaffId = staffId;

    // if BON -> wait mongo
    if (staffId.startsWith("BON")) {
      final mongo = await waitForRegisteredStaffMongoId();
      if (mongo != null && mongo.isNotEmpty) fixedStaffId = mongo;
    }

    // still BON -> do not emit wrong id
    if (fixedStaffId.startsWith("BON")) {
      AppLogger.log.e("⛔ join_chat blocked: staff mongo id not ready");
      _chatErrorCtrl.add({"message": "Staff not registered yet. Retry join."});
      return;
    }

    final payload = {"staffId": fixedStaffId, "userId": userId};
    AppLogger.log.i("💡 ➡️ join_chat emit: $payload");
    socket.emit("join_chat", payload);
  }

  /// (Optional) keep old joinChat but DO NOT use it
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

    final payload = {"staffId": fixedStaffId, "userId": userId, "message": message};
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
    // register will emit only in onConnect
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

      if (_lastRegisterEvent != null) {
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
  String? registeredStaffMongoId;

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
  String _baseUrl = "https://bondinig-ca63248fdb11.herokuapp.com";
  String? _lastRegisterEvent; // register_user / register_staff / staff_online

  // avoid duplicate connect
  Future<void>? _connectInProgress;

  // flip true when server sends registered_user/registered_staff
  bool _registeredOk = false;

  // ----------------------------
  // PUBLIC: Connect (NO TOKEN PARAMS)
  // ----------------------------

  /// ✅ CHAT USER (register_user with NO payload)
  Future<void> connectUserRegister({String? baseUrl}) async {
    _lastRegisterEvent = "register_user";
    if (baseUrl != null) _baseUrl = baseUrl;

    // If already connected, register immediately
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

  /// ✅ OLD: staff_online (only if old backend supports)
  Future<void> connectStaff(String staffMemberId, {String? baseUrl}) async {
    _lastRegisterEvent = "staff_online";
    if (baseUrl != null) _baseUrl = baseUrl;

    await _ensureConnected(); // connect only

    if (isConnected) {
      socket.emit("staff_online", {"memberID": staffMemberId});
      AppLogger.log.i("🟢 staff_online emitted → $staffMemberId");
    }
  }

  void listenStaffList(Function(dynamic) onUpdate) {
    _socket?.on("get_staff_list", (data) => onUpdate(data));
  }
  Future<String?> waitForRegisteredStaffMongoId({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // already available
    if (registeredStaffMongoId != null && registeredStaffMongoId!.isNotEmpty) {
      return registeredStaffMongoId;
    }

    final completer = Completer<String?>();
    StreamSubscription? sub;

    sub = registeredStaffStream.listen((data) {
      try {
        final m = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        final sid = (m["staffId"] ?? "").toString();
        if (sid.isNotEmpty) {
          registeredStaffMongoId = sid;
          if (!completer.isCompleted) completer.complete(sid);
          sub?.cancel();
        }
      } catch (_) {}
    });

    // timeout safety
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(registeredStaffMongoId);
        sub?.cancel();
      }
    });

    return completer.future;
  }

  // ----------------------------
  // CHAT ACTIONS
  // ----------------------------
  void joinChat({required String staffId, required String userId}) {
    if (!isConnected) return;

    final fixedStaffId = (staffId.startsWith("BON"))
        ? (registeredStaffMongoId ?? staffId)
        : staffId;

    final payload = {"staffId": fixedStaffId, "userId": userId};
    AppLogger.log.i("💡 ➡️ join_chat emit: $payload");
    socket.emit("join_chat", payload);
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

  // ----------------------------
  // CORE: ensure connected once
  // ----------------------------
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

  // ----------------------------
  // CORE: ensure connected + registered once
  // IMPORTANT FIX:
  //  - DO NOT emit register here (only in onConnect)
  // ----------------------------
  Future<void> _ensureConnectedAndRegistered() async {
    if (isConnected && _registeredOk == true) return;
    await _ensureConnected();
    // ✅ register will happen ONLY in onConnect()
  }

  // ----------------------------
  // Actual socket connect (base)
  // ----------------------------
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

      // ✅ ONLY PLACE we emit register (prevents double register)
      if (_lastRegisterEvent != null) {
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

    // ✅ MUST listeners
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
      // do not dedupe here (dedupe in UI by _id)
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

    // optional existing events
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
  // Add inside SocketService class

  void sendMessageWithAck({
    required String staffId,
    required String userId,
    required String message,
    required Function(dynamic res) onAck,
  }) {
    if (!isConnected) {
      onAck({"ok": false, "message": "socket not connected"});
      return;
    }

    final payload = {"staffId": staffId, "userId": userId, "message": message};
    AppLogger.log.i("💡 ➡️ send_message emit (ack): $payload");

    // socket.io ack callback (last argument)
    socket.emitWithAck(
      "send_message",
      payload,
      ack: (data) {
        onAck(data);
      },
    );
  }

  void reconnect() {
    if (isConnected) return;
    _scheduleReconnect();
  }

  // ----------------------------
  // Cleanup
  // ----------------------------
  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _registeredOk = false;
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





//
// import 'package:socket_io_client/socket_io_client.dart' as IO;
//
// class SocketService {
//   static final SocketService _instance = SocketService._internal();
//
//   factory SocketService() => _instance;
//
//   late IO.Socket socket;
//
//   SocketService._internal();
//
//   void connectStaff(String staffMemberId) {
//     socket = IO.io(
//       // "https://bondingbackend.onrender.com",
//       "https://bondinig-ca63248fdb11.herokuapp.com",
//       IO.OptionBuilder()
//           .setTransports(['websocket'])
//           .disableAutoConnect()
//           .build(),
//     );
//
//     socket.connect();
//
//     socket.onConnect((_) {
//       print("✅ Socket connected: ${socket.id}");
//
//       // 🔥 EMIT STAFF ONLINE
//       socket.emit("staff_online", {"memberID": staffMemberId});
//
//       print("🟢 staff_online emitted → $staffMemberId");
//     });
//
//     socket.on("staff_status_changed", (data) {
//       print("📡 Staff status update: $data");
//     });
//
//     socket.onDisconnect((_) {
//       print("❌ Socket disconnected");
//     });
//
//     socket.onConnectError((err) {
//       print("⚠ Socket error: $err");
//     });
//   }
//
//   void listenStaffList(Function(dynamic) onUpdate) {
//     socket.on("get_staff_list", (data) {
//       print("📡 Staff list update: $data");
//
//       onUpdate(data);
//     });
//   }
//
//   void disconnect() {
//     socket.dispose();
//   }
// }
