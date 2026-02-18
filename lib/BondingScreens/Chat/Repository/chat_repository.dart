import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:flutter/foundation.dart';

class ChatRepository {
  final NetworkApiService _apiService;
  ChatRepository(this._apiService);

  /// ✅ GET: /api/v1/auth/user/chat/history/:staffId?page=1&limit=50
  Future<Map<String, dynamic>> getChatHistory({
    required String staffId,
    required bool isStaff,
    required int page,
    required int limit,
  }) async {
    try {
      // ✅ IMPORTANT: send only endpoint path (NO baseUrl here)
      final endpoint = isStaff
          ? "staff/chat/history/$staffId"
          : "auth/user/chat/history/$staffId";

      final response = await _apiService.getResponseV2(endpoint);

      if (kDebugMode) {
        print("Chat History Response: $response");
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception("ChatRepository getChatHistory error: $e");
    }
  }
  Future<Map<String, dynamic>> getUserChatList({
    required int page,
    required int limit,
  }) async {
    final url =
        "auth/user/chat/list?page=$page&limit=$limit";
    final response = await _apiService.getResponseV2(url);
    return Map<String, dynamic>.from(response);
  }
}
