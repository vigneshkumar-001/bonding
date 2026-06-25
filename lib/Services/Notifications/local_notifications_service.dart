// lib/Services/Notifications/local_notifications_service.dart
//
// flutter_local_notifications wrapper used to RING the staff for an
// Admin -> Staff verification call (foreground / background / killed on Android,
// foreground / background on iOS).
//
// It shows a high-importance, full-screen-intent notification with
// Accept / Decline actions. Tapping the notification (or Accept) brings the app
// to the foreground; the AdminCallHandler then joins the ZEGO room.

import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/StaffScreenScreens/AdminVerifyCall/admin_call_payload.dart';

// Action / channel identifiers.
// NOTE: the channel id is "_ring" so a fresh channel (with the ringtone sound +
// vibration) is created. Android caches channel settings, so changing sound on
// an existing channel id is ignored until reinstall — a new id avoids that.
const String kAdminCallChannelId = 'admin_verify_call_ring';
const String kAdminCallChannelName = 'Verification calls';
const String kAdminCallChannelDesc =
    'Incoming admin verification video calls';
const String kAcceptActionId = 'accept_admin_call';
const String kDeclineActionId = 'decline_admin_call';
const int kAdminCallNotificationId = 778899;

// Ring sound = same mp3 the men -> women (ZEGO) calls use, copied to
// android/app/src/main/res/raw/incoming_call.mp3.
const RawResourceAndroidNotificationSound kRingSound =
    RawResourceAndroidNotificationSound('incoming_call');

// Incoming-call style vibration (wait, buzz, pause, buzz, ...).
final Int64List kRingVibration =
    Int64List.fromList(<int>[0, 1000, 800, 1000, 800, 1000]);

/// Runs in a SEPARATE isolate when the user interacts with the notification
/// while the app is in the background / killed. We can only do lightweight work
/// here (cancel the notification). Accept is handled by the app being launched
/// to the foreground (see [LocalNotificationsService.consumeLaunchPayload]).
@pragma('vm:entry-point')
void adminCallNotificationBackgroundTap(NotificationResponse response) {
  // Decline -> just dismiss (cancelNotification:true already handles it).
  // Accept -> the app is launched (showsUserInterface:true), nothing to do here.
}

class LocalNotificationsService {
  static final LocalNotificationsService _instance =
      LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Foreground response routing. Set by AdminCallHandler.
  /// (accept/tap -> accept; decline -> decline)
  void Function(AdminCallPayload payload, bool accepted)? onAdminCallResponse;

  /// Set when the app was COLD-STARTED by tapping the call notification.
  /// AdminCallHandler consumes it once the navigator is ready.
  AdminCallPayload? _launchPayload;

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          kAdminCallChannelId,
          actions: [
            DarwinNotificationAction.plain(
              kAcceptActionId,
              'Accept',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              kDeclineActionId,
              'Decline',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    final settings =
        InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse:
          adminCallNotificationBackgroundTap,
    );

    await _createAndroidChannel();
    await _captureLaunchDetails();

    _initialized = true;
    AppLogger.log.i('LocalNotificationsService initialized');
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channel = AndroidNotificationChannel(
      kAdminCallChannelId,
      kAdminCallChannelName,
      description: kAdminCallChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: kRingSound,
      // Treat the alert as a ringtone (uses ring volume / longer alert).
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      enableVibration: true,
      vibrationPattern: kRingVibration,
      enableLights: true,
    );
    await android.createNotificationChannel(channel);
  }

  /// Request OS notification permission (Android 13+, iOS). Best-effort.
  Future<void> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      AppLogger.log.w('requestPermissions failed: $e');
    }
  }

  /// Was the app launched by tapping the call notification? If so, capture the
  /// payload so AdminCallHandler can auto-join once the UI is ready.
  Future<void> _captureLaunchDetails() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || details.didNotificationLaunchApp != true) return;
      final resp = details.notificationResponse;
      if (resp == null) return;
      if (resp.actionId == kDeclineActionId) return; // declined -> ignore
      final payloadStr = resp.payload;
      if (payloadStr == null || payloadStr.isEmpty) return;
      final p = AdminCallPayload.fromJsonString(payloadStr);
      if (p.isVerifyCall && p.isValid) {
        _launchPayload = p;
        AppLogger.log.i('Captured cold-start admin call payload: $p');
      }
    } catch (e) {
      AppLogger.log.w('captureLaunchDetails failed: $e');
    }
  }

  /// Returns and clears any cold-start payload.
  AdminCallPayload? consumeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  void _onForegroundResponse(NotificationResponse response) {
    try {
      final payloadStr = response.payload;
      if (payloadStr == null || payloadStr.isEmpty) return;
      final p = AdminCallPayload.fromJsonString(payloadStr);
      if (!p.isVerifyCall) return;
      final declined = response.actionId == kDeclineActionId;
      onAdminCallResponse?.call(p, !declined);
    } catch (e) {
      AppLogger.log.e('onForegroundResponse failed: $e');
    }
  }

  /// Show the ringing notification for an incoming admin verification call.
  Future<void> showIncomingAdminCall(AdminCallPayload p) async {
    if (!_initialized) {
      await init();
    }

    final caller = p.callerName.isNotEmpty ? p.callerName : 'Admin';

    final androidDetails = AndroidNotificationDetails(
      kAdminCallChannelId,
      kAdminCallChannelName,
      channelDescription: kAdminCallChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: true,
      sound: kRingSound,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      enableVibration: true,
      vibrationPattern: kRingVibration,
      ticker: 'Incoming verification call',
      actions: const [
        AndroidNotificationAction(
          kAcceptActionId,
          'Accept',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          kDeclineActionId,
          'Decline',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: kAdminCallChannelId,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.show(
        id: kAdminCallNotificationId,
        title: 'Incoming verification call',
        body: '$caller is calling to verify your profile',
        notificationDetails: details,
        payload: p.toJsonString(),
      );
    } catch (e) {
      AppLogger.log.e('showIncomingAdminCall failed: $e');
    }
  }

  Future<void> cancelIncoming() async {
    try {
      await _plugin.cancel(id: kAdminCallNotificationId);
    } catch (_) {}
  }
}
