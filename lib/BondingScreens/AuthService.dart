// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'user_id';     // optional
  static const String _keyPhone = 'user_phone';   // optional

  // Save after successful login
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

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    print("Token ::::::: $token");
    return token != null && token.isNotEmpty;
  }

  // Logout / clear
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);
  }
}