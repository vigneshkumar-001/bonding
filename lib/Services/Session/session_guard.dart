// lib/Services/Session/session_guard.dart
//
// Single source of truth for admin BLOCK / DELETE enforcement on the client.
//
// Triggered by:
//   * HTTP 403 with body { blocked:true } or { deleted:true }  (NetworkApiService.inspect)
//   * Socket "force_logout" event while online                 (wired in main.dart)
//
// On an AUTHENTICATED session it force-logs-out: clears the JWT + session,
// disconnects socket/zego/zimkit (via AuthService.logout), shows a friendly
// dialog, and returns the user to the login entry. During a LOGIN attempt
// (no token yet) it does nothing here — the login screen surfaces the
// server message itself.
//
// forceLogout() is idempotent (interceptor + socket may both fire).

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen2.dart';

class SessionGuard {
  static final SessionGuard _instance = SessionGuard._internal();
  factory SessionGuard() => _instance;
  SessionGuard._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _loggingOut = false;
  bool _dialogShowing = false;

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Called for EVERY API response (see NetworkApiService). Detects a
  /// blocked/deleted 403 and reacts. Cheap no-op for everything else.
  void inspect(int statusCode, String rawBody) {
    if (statusCode != 403) return;
    if (rawBody.isEmpty) return;

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return; // not JSON -> ignore
    }
    if (body == null) return;

    final blocked = body['blocked'] == true;
    final deleted = body['deleted'] == true;
    if (!blocked && !deleted) return;

    final message = body['message']?.toString();
    _onForbidden(message: message, deleted: deleted);
  }

  /// Socket "force_logout" payload: { reason, message }.
  void onSocketForceLogout(dynamic data) {
    try {
      final map = (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final reason = (map['reason'] ?? '').toString().toLowerCase();
      final message = map['message']?.toString();
      // A socket force_logout always targets an active session.
      forceLogout(message: message, deleted: reason == 'deleted');
    } catch (e) {
      AppLogger.log.e('onSocketForceLogout failed: $e');
    }
  }

  Future<void> _onForbidden({String? message, required bool deleted}) async {
    // Only force-logout if there is actually a session. During a login attempt
    // there is no token yet -> let the login screen show the message itself.
    final token = await AuthService.getToken();
    final hasSession = (token ?? '').trim().isNotEmpty;
    if (hasSession) {
      await forceLogout(message: message, deleted: deleted);
    } else {
      // Login attempt into a blocked/deleted account: stay on the login
      // screen, just show the clean friendly message.
      _showBlockedDialog(message: message, deleted: deleted);
    }
  }

  /// Idempotent. Safe to call from the interceptor and the socket at once.
  Future<void> forceLogout({String? message, bool deleted = false}) async {
    if (_loggingOut) return;
    _loggingOut = true;

    AppLogger.log.w('SessionGuard.forceLogout (deleted=$deleted): $message');

    try {
      await AuthService.logout(); // clears token + socket + zego + zimkit + admin call
    } catch (e) {
      AppLogger.log.e('forceLogout: AuthService.logout failed: $e');
    }

    final nav = _navigatorKey?.currentState;
    if (nav != null) {
      try {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen2()),
          (route) => false,
        );
      } catch (e) {
        AppLogger.log.e('forceLogout: navigation failed: $e');
      }
    }

    _showBlockedDialog(message: message, deleted: deleted);

    // Re-enable after a short window: dedupes the simultaneous interceptor +
    // socket double-fire, while allowing a future session to be logged out too.
    Future.delayed(const Duration(seconds: 5), () => _loggingOut = false);
  }

  void _showBlockedDialog({String? message, required bool deleted}) {
    final text = (message != null && message.trim().isNotEmpty)
        ? message.trim()
        : (deleted
            ? 'Your account has been removed by admin.'
            : 'Your account has been blocked. Please contact support.');

    if (_dialogShowing) return;
    _dialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey?.currentContext;
      if (ctx == null) {
        // Fallback: at least toast the message.
        _dialogShowing = false;
        Utils.snackBarErrorMessage(text);
        return;
      }
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) => _BlockedDialog(message: text, deleted: deleted),
      ).whenComplete(() => _dialogShowing = false);
    });
  }
}

class _BlockedDialog extends StatelessWidget {
  final String message;
  final bool deleted;

  const _BlockedDialog({required this.message, required this.deleted});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1422),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (deleted ? const Color(0xFFFF6F61) : const Color(0xFFFFC107))
                    .withOpacity(0.15),
              ),
              child: Icon(
                deleted ? Icons.person_off_rounded : Icons.block_rounded,
                color: deleted ? const Color(0xFFFF6F61) : const Color(0xFFFFC107),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              deleted ? 'Account Removed' : 'Account Blocked',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC7C7CC),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A5CFF), Color(0xFFFF5CA8)],
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
