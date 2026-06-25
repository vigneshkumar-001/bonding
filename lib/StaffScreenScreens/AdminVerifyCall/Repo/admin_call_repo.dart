// lib/StaffScreenScreens/AdminVerifyCall/Repo/admin_call_repo.dart
//
// Backend calls for the Admin -> Staff verification call.
// Reuses the existing authenticated HTTP client (Bearer <STAFF_JWT> is added
// automatically by NetworkApiService.postResponseV2 / getResponseV2).

import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';

class AdminCallRepo {
  final NetworkApiService _api;
  final ApiEndPoints _endpoints = ApiEndPoints();

  AdminCallRepo([NetworkApiService? api]) : _api = api ?? NetworkApiService();

  /// POST /api/v1/staff/registerFcmToken  { "fcmToken": "device token" }
  /// Returns true on a 2xx-style success. Never throws (best-effort).
  Future<bool> registerFcmToken(String fcmToken) async {
    if (fcmToken.trim().isEmpty) return false;
    try {
      final res = await _api.postResponseV2(
        _endpoints.staffRegisterFcmToken,
        body: {"fcmToken": fcmToken.trim()},
      );
      final ok = _looksSuccessful(res);
      AppLogger.log.i("registerFcmToken => ok=$ok");
      return ok;
    } catch (e) {
      AppLogger.log.e("registerFcmToken failed: $e");
      return false;
    }
  }

  /// GET /api/v1/staff/zegoToken  -> { data: { appID, token, zegoUserID } }
  /// Returns the inner `data` map, or null on failure.
  Future<Map<String, dynamic>?> getZegoToken() async {
    try {
      final res = await _api.getResponseV2(_endpoints.staffZegoToken);
      final data = res['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      AppLogger.log.e("getZegoToken failed: $e");
      return null;
    }
  }

  bool _looksSuccessful(dynamic res) {
    if (res is Map) {
      final m = Map<String, dynamic>.from(res);
      if (m.containsKey('success')) return m['success'] == true;
      if (m.containsKey('status')) {
        final s = m['status'];
        return s == true || s == 'success' || s == 200 || s == '200';
      }
      // No explicit flag but we got a map back => treat as success.
      return true;
    }
    // Non-map (e.g. plain string body) => assume the POST went through.
    return res != null;
  }
}
