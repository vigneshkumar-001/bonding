// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'package:bonding_app/Socket/socket_service.dart';

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
    return token != null && token.isNotEmpty;
  }

  // ✅ Logout / clear + disconnect services
  static Future<void> logout() async {
    // 1) ✅ Disconnect Zego Call Invitation Service
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit();
    } catch (_) {
      // no-op: best effort cleanup
    }

    // 2) ✅ Disconnect ZIMKit (Chat)
    try {
      await ZIMKit().disconnectUser();
    } catch (_) {
      // no-op: best effort cleanup
    }

    // 3) ✅ Disconnect Socket (Staff socket)
    try {
      SocketService().disconnect(); // உங்கள் socket_service.dart ல disconnect method இருக்கணும்
    } catch (_) {
      // no-op: best effort cleanup
    }

    // 4) ✅ Clear local saved auth data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);

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
