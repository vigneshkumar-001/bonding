import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallController extends ChangeNotifier {
  // ─────────────────────────────────────────────
  // Internal State (was your screen variables)
  // ─────────────────────────────────────────────
  bool _zegoInitialized = true; // set true if you init in main()
  String _zegoLocalId = '';
  bool _zegoLocalReady = false;

  bool _pendingCall = false;
  bool _wasCallReallyConnected = false;
  DateTime? _callStartTime;

  int _maxAllowedSeconds = 0;
  int _currentCallPricePerMin = 0;
  bool _isCurrentCallVideo = false;
  String _staffMongoId = '';

  Timer? _inviteTimeoutTimer;
  Timer? _callLimitTimer;

  // ─────────────────────────────────────────────
  // Getters (optional)
  // ─────────────────────────────────────────────
  bool get pendingCall => _pendingCall;
  bool get wasCallReallyConnected => _wasCallReallyConnected;
  String get zegoLocalId => _zegoLocalId;

  // If you want to manually toggle this from app init
  void setZegoInitialized(bool v) {
    _zegoInitialized = v;
  }

  // ─────────────────────────────────────────────
  // Safe: get ZEGO local user id
  // ─────────────────────────────────────────────
  String _getZegoLocalUserIDSafe() {
    try {
      final id = ZegoUIKit().getLocalUser().id;
      return (id).trim();
    } catch (_) {
      return '';
    }
  }

  void _safeSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    try {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      // Ignore: context could be deactivated while async work completes.
    }
  }

  // ─────────────────────────────────────────────
  // Public: Common START CALL (Audio/Video)
  // ─────────────────────────────────────────────
  Future<void> startCall({
    required BuildContext context,
    required bool enabled,
    required bool isTargetOnline,
    required int pricePerMin,
    required bool isVideoCall,
    required String targetUserID, // staff.memberID (zego id)
    required String targetUserName,
    required String targetStaffMongoId, // staff._id (mongo)
  }) async {
    if (!context.mounted) return;

    final userVM = context.read<UserViewModel>();
    final balance = userVM.currentUser?.coinBalance ?? 0;

    if (!enabled) {
      _safeSnack(context, "Call service still connecting, try again.");
      return;
    }

    if (!isTargetOnline) {
      _safeSnack(context, "User is offline");
      return;
    }

    if (balance < pricePerMin) {
      _safeSnack(context, "Insufficient balance");
      return;
    }

    // Permissions
    final statuses = await [
      Permission.microphone,
      if (isVideoCall) Permission.camera,
    ].request();

    if (!context.mounted) return;

    if (!statuses[Permission.microphone]!.isGranted ||
        (isVideoCall && !statuses[Permission.camera]!.isGranted)) {
      _safeSnack(context, "Permissions required");
      return;
    }

    // Max seconds allowed
    _maxAllowedSeconds = (balance ~/ pricePerMin) * 60;

    // Send invite
    final ok = await sendInviteWithLogs(
      context: context,
      targetUserID: targetUserID,
      targetUserName: targetUserName,
      isVideoCall: isVideoCall,
      pricePerMin: pricePerMin,
    );

    if (!ok) {
      if (!context.mounted) return;
      _safeSnack(context, "Failed to send invitation");
      return;
    }

    // Set tracking state
    _pendingCall = true;
    _staffMongoId = targetStaffMongoId;
    _currentCallPricePerMin = pricePerMin;
    _isCurrentCallVideo = isVideoCall;

    _wasCallReallyConnected = false;
    _callStartTime = null;

    notifyListeners();

    if (!context.mounted) return;
    _startInviteTimeoutTimer(context);
  }

  // ─────────────────────────────────────────────
  // Your _sendInviteWithLogs moved here
  // ─────────────────────────────────────────────
  Future<bool> sendInviteWithLogs({
    required BuildContext context,
    required String targetUserID,
    required String targetUserName,
    required bool isVideoCall,
    required int pricePerMin,
  }) async {
    if (!context.mounted) return false;

    final userVM = context.read<UserViewModel>();
    final myVmId = (userVM.currentUser?.memberID ?? '').trim();

    final inviteeId = targetUserID.trim();
    final inviteeName = (targetUserName.isEmpty ? "User" : targetUserName).trim();

    // refresh local status
    final zegoLocal = _getZegoLocalUserIDSafe();
    if (zegoLocal.isNotEmpty) {
      _zegoLocalId = zegoLocal;
      if (!_zegoLocalReady) _zegoLocalReady = true;
    }

    if (inviteeId.isEmpty) return false;
    if (!_zegoInitialized) return false;

    // important guard
    if (_zegoLocalId.isEmpty) {
      _safeSnack(context, "Call service still connecting. Try again.");
      return false;
    }

    // self-call protections
    if (inviteeId == myVmId || inviteeId == _zegoLocalId) {
      return false;
    }

    try {
      final callID = "${_zegoLocalId}_to_${inviteeId}_${DateTime.now().millisecondsSinceEpoch}";

      final ok = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [
          ZegoCallUser.fromUIKit(
            ZegoUIKitUser(id: inviteeId, name: inviteeName),
          ),
        ],
        isVideoCall: isVideoCall,
        callID: callID,
        customData: jsonEncode({"price_per_min": pricePerMin}),
        timeoutSeconds: 60,
      );

      return ok;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Invite timeout (was your _startInviteTimeoutTimer)
  // ─────────────────────────────────────────────
  void _startInviteTimeoutTimer(BuildContext context) {
    _inviteTimeoutTimer?.cancel();
    _inviteTimeoutTimer = Timer(const Duration(seconds: 70), () {
      if (_pendingCall && !_wasCallReallyConnected) {
        _resetCallTracking();
        notifyListeners();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Call connected hook (call this when room connected)
  // ─────────────────────────────────────────────
  void markCallConnected(BuildContext context) {
    _wasCallReallyConnected = true;
    _callStartTime = DateTime.now();
    _startCallLimitTimer(context);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Call limit timer (was your _startCallLimitTimer)
  // ─────────────────────────────────────────────
  void _startCallLimitTimer(BuildContext context) {
    _callLimitTimer?.cancel();
    if (_maxAllowedSeconds <= 0) return;

    _callLimitTimer = Timer(Duration(seconds: _maxAllowedSeconds), () {
      ZegoUIKit().leaveRoom();
      handleCallEnd(context, staffMongoId: _staffMongoId, isVideoCall: _isCurrentCallVideo);

      _safeSnack(context, "Call ended: Time limit reached");
    });
  }

  // ─────────────────────────────────────────────
  // Billing + call end (was your _handleCallEnd)
  // ─────────────────────────────────────────────
  void handleCallEnd(
      BuildContext context, {
        required String staffMongoId,
        required bool isVideoCall,
      }) {
    // no real connect
    if (!_wasCallReallyConnected || _callStartTime == null) {
      _resetCallTracking();
      notifyListeners();
      return;
    }

    final durationSeconds = DateTime.now().difference(_callStartTime!).inSeconds;

    // too short
    if (durationSeconds < 15) {
      _resetCallTracking();
      notifyListeners();
      return;
    }

    _callLimitTimer?.cancel();
    _inviteTimeoutTimer?.cancel();

    final minutesFraction = durationSeconds / 60.0;
    final spent = (minutesFraction * _currentCallPricePerMin).ceil();

    final userVM = context.read<UserViewModel>();
    final currentBalance = userVM.currentUser?.coinBalance ?? 0;
    final newBalance = currentBalance - spent;

    userVM.updateUserCoinBalance(
      newBalance,
      staffMongoId,
      spent,
      durationSeconds.toString(),
      isVideoCall ? "video" : "audio",
    );
    userVM.updateLocalCoinBalance(newBalance);

    _resetCallTracking();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Reset
  // ─────────────────────────────────────────────
  void _resetCallTracking() {
    _pendingCall = false;
    _wasCallReallyConnected = false;
    _callStartTime = null;

    _maxAllowedSeconds = 0;
    _currentCallPricePerMin = 0;
    _isCurrentCallVideo = false;
    _staffMongoId = '';

    _inviteTimeoutTimer?.cancel();
    _inviteTimeoutTimer = null;

    _callLimitTimer?.cancel();
    _callLimitTimer = null;
  }

  // ─────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────
  @override
  void dispose() {
    _inviteTimeoutTimer?.cancel();
    _callLimitTimer?.cancel();
    super.dispose();
  }
}
