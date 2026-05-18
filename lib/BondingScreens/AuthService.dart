// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyPhone = 'user_phone';

  static Future<void> saveLoginData({
    required String token,
    String? userId,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (userId != null) await prefs.setString(_keyUserId, userId);
    if (phone != null) await prefs.setString(_keyPhone, phone);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    print("Token ::::::: $token");
    return token != null && token.isNotEmpty;
  }

  // ✅ Logout / clear + disconnect services
  static Future<void> logout() async {
    // 1) ✅ Disconnect Zego Call Invitation Service
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
      print("✅ Zego Invitation Service uninit success");
    } catch (e) {
      print("⚠️ Zego uninit failed: $e");
    }

    // 2) ✅ Disconnect ZIMKit (Chat)
    try {
      await ZIMKit().disconnectUser();
      print("✅ ZIMKit disconnect success");
    } catch (e) {
      print("⚠️ ZIMKit disconnect failed: $e");
    }

    // 3) ✅ Disconnect Socket (Staff socket)
    try {
      final socketSvc = SocketService();
      AppLogger.log.i(
        "Logout: socket snapshot(before) => ${socketSvc.debugSnapshot()}",
      );
      if ((socketSvc.lastSocketError ?? "").trim().isNotEmpty) {
        AppLogger.log.w(
          "Logout: socket last error => ${socketSvc.lastSocketError}",
        );
        print("⚠️ Socket last error: ${socketSvc.lastSocketError}");
      }
      socketSvc.resetForLogout(); // disconnect + clear runtime cache
      AppLogger.log.i(
        "Logout: socket snapshot(after) => ${socketSvc.debugSnapshot()}",
      );
      print("✅ Socket disconnect+reset success");
    } catch (e) {
      print("⚠️ Socket disconnect failed: $e");
    }

    // 4) ✅ Clear local saved auth data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);

    print("✅ Auth cleared");
  }
}

// // lib/services/auth_service.dart
// import 'package:shared_preferences/shared_preferences.dart';
//
// class AuthService {
//   static const String _keyToken = 'auth_token';
//   static const String _keyUserId = 'user_id'; // optional
//   static const String _keyPhone = 'user_phone'; // optional
//
//   // Save after successful login
//   static Future<void> saveLoginData({
//     required String token,
//     String? userId,
//     String? phone,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_keyToken, token);
//     if (userId != null) await prefs.setString(_keyUserId, userId);
//     if (phone != null) await prefs.setString(_keyPhone, phone);
//   }
//
//   // Get token
//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_keyToken);
//   }
//
//   // Check if logged in
//   static Future<bool> isLoggedIn() async {
//     final token = await getToken();
//     print("Token ::::::: $token");
//     return token != null && token.isNotEmpty;
//   }
//
//   // Logout / clear
//   static Future<void> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_keyToken);
//     await prefs.remove(_keyUserId);
//     await prefs.remove(_keyPhone);
//   }
// }
