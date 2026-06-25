// lib/StaffScreenScreens/AdminVerifyCall/admin_verify_call_screen.dart
//
// Staff joins the admin's ZEGO verification room using TOKEN auth
// (appSign empty, server Token04 used as-is). Same AppID as the rest of the app.

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Services/Notifications/local_notifications_service.dart';
import 'package:bonding_app/StaffScreenScreens/AdminVerifyCall/admin_call_payload.dart';

class AdminVerifyCallScreen extends StatefulWidget {
  final AdminCallPayload payload;

  const AdminVerifyCallScreen({super.key, required this.payload});

  @override
  State<AdminVerifyCallScreen> createState() => _AdminVerifyCallScreenState();
}

class _AdminVerifyCallScreenState extends State<AdminVerifyCallScreen> {
  @override
  void initState() {
    super.initState();
    // Make sure any lingering ring notification is gone once we're in the call.
    LocalNotificationsService().cancelIncoming();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      await [Permission.camera, Permission.microphone].request();
    } catch (e) {
      AppLogger.log.w('admin call permission request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;

    if (!p.isValid) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Invalid call details',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return ZegoUIKitPrebuiltCall(
      appID: p.appID,
      appSign: '', // token auth -> must stay empty
      token: p.token, // server-generated ZEGO Token04, used as-is
      userID: p.zegoUserID, // "staff_<staffId>"
      userName: p.safeUserName,
      callID: p.roomID, // MUST equal the payload roomID
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          LocalNotificationsService().cancelIncoming();
          // Default behavior: leave the room and pop this page.
          defaultAction.call();
        },
      ),
    );
  }
}
