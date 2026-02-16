import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  late IO.Socket socket;

  SocketService._internal();

  void connectStaff(String staffMemberId) {
    socket = IO.io(
      // "https://bondingbackend.onrender.com",
      "https://bondinig-ca63248fdb11.herokuapp.com",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("✅ Socket connected: ${socket.id}");

      // 🔥 EMIT STAFF ONLINE
      socket.emit("staff_online", {"memberID": staffMemberId});

      print("🟢 staff_online emitted → $staffMemberId");
    });

    socket.on("staff_status_changed", (data) {
      print("📡 Staff status update: $data");
    });

    socket.onDisconnect((_) {
      print("❌ Socket disconnected");
    });

    socket.onConnectError((err) {
      print("⚠ Socket error: $err");
    });
  }

  void listenStaffList(Function(dynamic) onUpdate) {
    socket.on("get_staff_list", (data) {
      print("📡 Staff list update: $data");

      onUpdate(data);
    });
  }

  void disconnect() {
    socket.dispose();
  }
}
