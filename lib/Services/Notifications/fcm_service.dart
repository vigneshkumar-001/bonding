// lib/Services/Notifications/fcm_service.dart
//
// Firebase Cloud Messaging integration for the Admin -> Staff verification call.
//
// Delivery paths handled here:
//   * Foreground  : FirebaseMessaging.onMessage  (data type "admin_verify_call")
//   * Background  : top-level firebaseMessagingBackgroundHandler -> rings via
//                   local notification (works when app is backgrounded/killed
//                   on Android; iOS requires the app to be wakeable)
//   * App opened from a push: onMessageOpenedApp / getInitialMessage
//
// The actual ringing UI + ZEGO join is delegated to callbacks set by
// AdminCallHandler so this file stays decoupled from navigation.

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/firebase_options.dart';
import 'package:bonding_app/StaffScreenScreens/AdminVerifyCall/admin_call_payload.dart';
import 'package:bonding_app/StaffScreenScreens/AdminVerifyCall/Repo/admin_call_repo.dart';
import 'package:bonding_app/Services/Notifications/local_notifications_service.dart';

/// Top-level background/terminated FCM handler. MUST be a top-level function.
/// Runs in its own isolate, so it can only do lightweight work: show the ring.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  try {
    final data = message.data;
    if ((data['type'] ?? '').toString() == kAdminVerifyCallType) {
      final payload = AdminCallPayload.fromMap(data);
      if (payload.isValid) {
        await LocalNotificationsService().showIncomingAdminCall(payload);
      }
    }
  } catch (e) {
    // Best-effort; never throw from a background isolate.
    AppLogger.log.e('bg FCM handler failed: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final AdminCallRepo _repo = AdminCallRepo();

  bool _initialized = false;
  bool _isStaffSession = false;

  /// Foreground incoming admin call (ring). Set by AdminCallHandler.
  void Function(AdminCallPayload payload)? onForegroundCall;

  /// App opened from a push that carried an admin call. Set by AdminCallHandler.
  void Function(AdminCallPayload payload)? onCallOpenedFromPush;

  /// Wire up FCM listeners. Idempotent. Call once (e.g. from main / handler).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      AppLogger.log.w('FCM requestPermission failed: $e');
    }

    try {
      // Show heads-up alerts for foreground pushes on iOS too.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    // Foreground messages.
    FirebaseMessaging.onMessage.listen((message) {
      final p = _parseAdminCall(message);
      if (p != null) onForegroundCall?.call(p);
    });

    // App brought to foreground by tapping a (notification) push.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final p = _parseAdminCall(message);
      if (p != null) onCallOpenedFromPush?.call(p);
    });

    // App cold-started by tapping a push.
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      final p = initial == null ? null : _parseAdminCall(initial);
      if (p != null) onCallOpenedFromPush?.call(p);
    } catch (_) {}

    // Token rotation -> re-register (staff sessions only).
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (_isStaffSession && token.isNotEmpty) {
        _repo.registerFcmToken(token);
      }
    });

    AppLogger.log.i('FcmService initialized');
  }

  /// Mark the current session as staff and push the device token to the backend.
  /// Called by AdminCallHandler.startForStaffSession (which is staff-gated).
  Future<void> registerTokenForStaff() async {
    _isStaffSession = true;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _logToken(token);
        await _repo.registerFcmToken(token);
      } else {
        AppLogger.log.w('FCM token was null/empty');
      }
    } catch (e) {
      AppLogger.log.e('registerTokenForStaff failed: $e');
    }
  }

  /// Prints the FULL device token so it can be copied for testing
  /// (e.g. Firebase console -> Cloud Messaging -> send test message).
  /// Look for the ===== FCM TOKEN ===== marker in the logs.
  void _logToken(String token) {
    AppLogger.log.i('===== FCM TOKEN (copy below) =====');
    AppLogger.log.i(token);
    AppLogger.log.i('===== END FCM TOKEN =====');
    // Also raw-print in case AppLogger truncates long lines.
    debugPrint('FCM_TOKEN=$token');
  }

  void markLoggedOut() {
    _isStaffSession = false;
  }

  AdminCallPayload? _parseAdminCall(RemoteMessage message) {
    try {
      final data = message.data;
      if ((data['type'] ?? '').toString() != kAdminVerifyCallType) return null;
      final p = AdminCallPayload.fromMap(data);
      return p.isValid ? p : null;
    } catch (e) {
      AppLogger.log.e('parseAdminCall failed: $e');
      return null;
    }
  }
}
