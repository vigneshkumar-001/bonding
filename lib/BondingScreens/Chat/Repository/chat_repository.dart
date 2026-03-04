import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
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
        AppLogger.log.i('Chat History Response: $response');
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      AppLogger.log.e(e);
      throw Exception("ChatRepository getChatHistory error: $e");
    }
  }

  Future<Map<String, dynamic>> getBlockedUsers({required bool isStaff}) async {
    try {
      // ✅ NOTE: endpoint path only (no base URL)
      final endpoint = isStaff
          ? "staff/chat/blocked-users"
          : "auth/user/chat/blocked-staff";

      final response = await _apiService.getResponseV2(endpoint);

      if (kDebugMode) {
        print("blocked User List Response: $response");
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      AppLogger.log.e(e);
      throw Exception("getBlockedUsers error: $e");
    }
  }

  Future<Map<String, dynamic>> getUserChatList({
    required int page,
    required int limit,
  }) async {
    final url = "auth/user/chat/list?page=$page&limit=$limit";
    final response = await _apiService.getResponseV2(url);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> unblockUser({
    required String userId,
    required bool isStaff,
  }) async {
    try {
      final endpoint = isStaff
          ? "staff/chat/unblock-user"
          : "auth/user/chat/unblock-staff";

      final body = !isStaff
          ? {"staffId": userId} // 🔥 when staff
          : {"userId": userId}; // 🔥 when user

      final response = await _apiService.postResponseV2(endpoint, body: body);

      if (kDebugMode) {
        print("Unblock User Response: $response");
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception("ChatRepository unblockUser error: $e");
    }
  }

  Future<Map<String, dynamic>> getDeleteAccountReasons({
    required bool isStaff,
  }) async {
    try {
      final endpoint = isStaff
          ? "staff/deleteAccountReasons"
          : "auth/user/deleteAccountReasons";
      final response = await _apiService.getResponseV2(endpoint);

      if (kDebugMode) {
        print("DeleteAccountReasons Response: $response");
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception("ChatRepository getDeleteAccountReasons error: $e");
    }
  }

  Future<Map<String, dynamic>> deleteAccount({
    required List<String> reasonCodes,
    required bool isStaff,
  }) async {
    try {
      final endpoint = isStaff
          ? "staff/deleteAccount"
          : "auth/user/deleteAccount";

      final body = {"reasonCodes": reasonCodes};

      final response = await _apiService.postResponseV2(endpoint, body: body);

      if (kDebugMode) {
        print("DeleteAccount Response: $response");
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception("ChatRepository deleteAccount error: $e");
    }
  }

  Future<Map<String, dynamic>> blockUser({
    required String userId,
    required String reason,
    required String staffId,
    required bool isStaff,
  }) async {
    try {
      final endpoint = isStaff
          ? "staff/chat/block-user"
          : "auth/user/chat/block-staff";
      final body = !isStaff
          ? {"staffId": staffId, "reason": reason}
          : {"userId": userId, "reason": reason};

      final response = await _apiService.postResponseV2(endpoint, body: body);

      if (kDebugMode) {
        print("blockedUsers  Response: $response");
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      AppLogger.log.e(e);
      throw Exception("blockedUsers error: $e");
    }
  }
}
