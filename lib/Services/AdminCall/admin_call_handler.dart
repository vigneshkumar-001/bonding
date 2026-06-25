// lib/Services/AdminCall/admin_call_handler.dart
//
// Central orchestrator for the Admin -> Staff verification call.
//
// Responsibilities:
//   * Start everything for a logged-in STAFF session (FCM register, socket
//     listener, notification callbacks). Idempotent.
//   * Receive the call from BOTH paths (socket `incoming_admin_call` +
//     FCM data `admin_verify_call`), de-duplicated by roomID.
//   * Ring via LocalNotificationsService; on Accept, join the ZEGO room.
//   * Handle cold-start (app launched by tapping the ring) via pending payload.
//
// This is the ONLY place that knows about navigation, so the services stay
// decoupled. Staff-gated: started only from staff entry points.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:bonding_app/Services/Notifications/fcm_service.dart';
import 'package:bonding_app/Services/Notifications/local_notifications_service.dart';
import 'package:bonding_app/StaffScreenScreens/AdminVerifyCall/admin_call_payload.dart';
import 'package:bonding_app/StaffScreenScreens/AdminVerifyCall/admin_verify_call_screen.dart';

class AdminCallHandler {
  static final AdminCallHandler _instance = AdminCallHandler._internal();
  factory AdminCallHandler() => _instance;
  AdminCallHandler._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  StreamSubscription? _socketSub;
  bool _started = false;
  bool _callScreenActive = false;

  // Dedup: roomID -> last-seen time (socket + FCM may both arrive).
  final Map<String, DateTime> _recent = {};

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Wire FCM/notification callbacks. Safe to call from `main` before login.
  void wireCallbacks() {
    FcmService().onForegroundCall = (p) => onIncoming(p, ring: true);
    FcmService().onCallOpenedFromPush = (p) => accept(p);
    LocalNotificationsService().onAdminCallResponse = (p, accepted) {
      if (accepted) {
        accept(p);
      } else {
        decline(p);
      }
    };
  }

  /// Start for a logged-in STAFF session. Idempotent.
  /// [staffMemberId] (BON… id) is optional; if given we (re)assert presence.
  Future<void> startForStaffSession({String? staffMemberId}) async {
    wireCallbacks();

    // Make sure the staff socket is registered so the backend can target it.
    try {
      final socket = SocketService();
      if (staffMemberId != null && staffMemberId.trim().isNotEmpty) {
        await socket.connectStaff(staffMemberId.trim());
      }
      await socket.connectStaffRegister();
    } catch (e) {
      AppLogger.log.w('admin-call: staff socket register failed: $e');
    }

    // Foreground socket path (subscribe once).
    _socketSub ??= SocketService().incomingAdminCallStream.listen((data) {
      try {
        if (data is Map) {
          final p = AdminCallPayload.fromMap(data);
          if (p.isVerifyCall && p.isValid) onIncoming(p, ring: true);
        }
      } catch (e) {
        AppLogger.log.e('admin-call: socket parse failed: $e');
      }
    });

    // FCM (idempotent) + register this device token to the backend.
    try {
      await FcmService().init();
      await FcmService().registerTokenForStaff();
    } catch (e) {
      AppLogger.log.w('admin-call: FCM init/register failed: $e');
    }

    _started = true;

    // Cold-start: app launched by tapping the ring notification.
    _routePendingAfterFrame();
  }

  void _routePendingAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay so the staff destination screen settles first.
      Future.delayed(const Duration(milliseconds: 700), () {
        final pending = LocalNotificationsService().consumeLaunchPayload();
        if (pending != null && pending.isValid) {
          accept(pending);
        }
      });
    });
  }

  /// Called from both delivery paths. De-dupes and rings.
  void onIncoming(AdminCallPayload p, {required bool ring}) {
    if (!p.isVerifyCall || !p.isValid) return;

    if (_isDuplicate(p.roomID)) {
      AppLogger.log.i('admin-call: duplicate ${p.roomID} ignored');
      return;
    }
    AppLogger.log.i('admin-call incoming: $p');

    if (ring) {
      LocalNotificationsService().showIncomingAdminCall(p);
    }
  }

  /// Join the ZEGO room.
  /// [attempt] is used internally to bound the "navigator not ready" retry so
  /// it can never loop forever.
  Future<void> accept(AdminCallPayload p, {int attempt = 0}) async {
    await LocalNotificationsService().cancelIncoming();

    // Haptic feedback when the staff actually taps Accept (once, not on retries).
    if (attempt == 0) {
      try {
        await HapticFeedback.heavyImpact();
        await HapticFeedback.vibrate();
      } catch (_) {}
    }

    if (!p.isValid) {
      AppLogger.log.w('admin-call: accept ignored, invalid payload');
      return;
    }
    if (_callScreenActive) {
      AppLogger.log.i('admin-call: call screen already active');
      return;
    }

    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      // ~12s worth of retries (30 * 400ms), then give up instead of looping.
      if (attempt >= 30) {
        AppLogger.log.e(
          'admin-call: navigator still not ready after $attempt tries, '
          'giving up on call ${p.roomID}',
        );
        return;
      }
      if (attempt == 0) {
        AppLogger.log.w('admin-call: navigator not ready, deferring accept');
      }
      Future.delayed(
        const Duration(milliseconds: 400),
        () => accept(p, attempt: attempt + 1),
      );
      return;
    }

    _callScreenActive = true;
    try {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => AdminVerifyCallScreen(payload: p),
        ),
      );
    } catch (e) {
      AppLogger.log.e('admin-call: push call screen failed: $e');
    } finally {
      _callScreenActive = false;
    }
  }

  Future<void> decline(AdminCallPayload p) async {
    await LocalNotificationsService().cancelIncoming();
    AppLogger.log.i('admin-call: declined ${p.roomID}');
    // No backend decline required (admin side times out / re-tries).
  }

  void stopForLogout() {
    try {
      _socketSub?.cancel();
    } catch (_) {}
    _socketSub = null;
    _started = false;
    _recent.clear();
    FcmService().markLoggedOut();
    LocalNotificationsService().cancelIncoming();
  }

  bool get isStarted => _started;

  bool _isDuplicate(String roomID) {
    final now = DateTime.now();
    // prune
    _recent.removeWhere((_, t) => now.difference(t).inSeconds > 120);
    final last = _recent[roomID];
    _recent[roomID] = now;
    return last != null && now.difference(last).inSeconds <= 90;
  }
}
