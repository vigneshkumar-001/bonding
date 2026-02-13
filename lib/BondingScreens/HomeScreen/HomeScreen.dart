// lib/BondingScreens/HomeScreen/HomeScreen.dart

import 'dart:async';
import 'dart:ui';

import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Socket.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

// ✅ logger
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ───────────────────────────────────────────────────────────────────────
  // Logger
  // ───────────────────────────────────────────────────────────────────────
  final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  void logI(String tag, String msg) => _log.i("[$tag] $msg");
  void logW(String tag, String msg) => _log.w("[$tag] $msg");
  void logE(String tag, String msg, [Object? e, StackTrace? st]) =>
      _log.e("[$tag] $msg", error: e, stackTrace: st);

  // ───────────────────────────────────────────────────────────────────────
  bool _zegoInitialized = false;
  bool _zegoInitializing = false;
  bool _isZimConnected = false;

  // ─── Call Tracking ──────────────────────────────────────────────────────
  bool _pendingCall = false; // ✅ NEW: send() happened, waiting for room login
  DateTime? _callStartTime; // ✅ now set only when room is logged-in
  String? _staffId;
  int? _currentCallPricePerMin;
  bool _isCurrentCallVideo = false;
  bool _wasCallReallyConnected = false;

  int _maxAllowedSeconds = 0; // based on balance
  Timer? _callLimitTimer; // ends call when max reached
  Timer? _inviteTimeoutTimer; // clears pending if not accepted
  Timer? _periodicCheckTimer;
  int _notInRoomCount = 0;

  final socketService = SocketService();

  // NOTE:
  // Your versions do NOT expose `connectionState` or invitation events.
  // So we keep logs based on init/send/room login states only.

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userVM = context.read<UserViewModel>();
      await userVM.fetchUserDetails();

      final user = userVM.currentUser;

      if (user != null && user.memberID.isNotEmpty) {
        logI(
          "INIT",
          "User fetched -> memberID=${user.memberID}, name=${user.name}",
        );

        await _connectZimUser(user);
        await _initZegoCallInvitation(user);
      } else {
        logW("INIT", "No valid user after fetchUserDetails()");
      }

      final staffVM = context.read<StaffViewModel>();
      await staffVM.fetchStaffDetails();

      if (staffVM.staffList.isNotEmpty) {
        final staffID = staffVM.staffList.first.memberID;
        logI("SOCKET", "Connecting socket as staff -> $staffID");

        socketService.connectStaff(staffID);
        socketService.listenStaffList((data) {
          staffVM.updateStaffPresence(data);
        });
      }
    });

    // ✅ Safety net: if call was connected and we suddenly leave room, end call after 5 checks
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_wasCallReallyConnected) return;

      if (!ZegoUIKit().isRoomLogin) {
        _notInRoomCount++;
        logW(
          "ROOM",
          "Not in room ($_notInRoomCount/5) connected=$_wasCallReallyConnected",
        );
        if (_notInRoomCount >= 5) {
          logW("ROOM", "Consecutive not-in-room -> handle end");
          _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
        }
      } else {
        _notInRoomCount = 0;
      }
    });
  }

  Future<void> _connectZimUser(UserProfile? user) async {
    if (user == null || _isZimConnected) return;

    try {
      logI("ZIM", "connectUser start -> id=${user.memberID}");

      await ZIMKit().connectUser(
        id: user.memberID.trim(),
        name: (user.name ?? "User_${user.memberID}").trim(),
        avatarUrl: user.image ?? "",
      );

      if (!mounted) return;
      setState(() => _isZimConnected = true);
      logI("ZIM", "connectUser SUCCESS -> ${user.memberID}");
    } catch (e, st) {
      logE("ZIM", "connectUser FAILED", e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Chat connection failed: ${e.toString().split('\n').first}",
            ),
          ),
        );
      }
    }
  }

  /// ✅ init call invitation service once
  /// Compatible with: zego_uikit_prebuilt_call ^4.22.2
  Future<void> _initZegoCallInvitation(UserProfile user) async {
    final ZegoUIKitSignalingPlugin _signalingPlugin =
        ZegoUIKitSignalingPlugin();

    if (_zegoInitialized || _zegoInitializing) return;

    try {
      _zegoInitializing = true;
      logI("ZEGO_INIT", "init start -> user=${user.memberID}");

      await ZegoUIKitPrebuiltCallInvitationService().init(
        plugins: [_signalingPlugin],
        appID: 467997506,
        appSign:
            "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",
        userID: user.memberID.trim(),
        userName: (user.name ?? "User").trim(),
        // ✅ DO NOT pass signaling plugin (not needed for your setup + avoids mismatches)
        // plugins: [ZegoUIKitSignalingPlugin()],  // <-- remove in your versions
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoAndroidNotificationConfig(
            channelID: "ZegoUIKit",
            channelName: "Call Notifications",
            sound: "zego_incoming",
            icon: "notification_icon",
          ),
          iOSNotificationConfig: ZegoIOSNotificationConfig(
            isSandboxEnvironment: false,
          ),
        ),
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
            logW(
              "CALL_END",
              "reason=${event.reason.name} pending=$_pendingCall connected=$_wasCallReallyConnected",
            );
            // If a call was pending/active, handle end safely
            if (_pendingCall || _wasCallReallyConnected) {
              _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
            } else {
              _resetCallTracking();
            }
            defaultAction.call();
          },
          user: ZegoCallUserEvents(
            onLeave: (user) {
              logW("REMOTE_LEAVE", "user=${user.id}");
              if (_pendingCall || _wasCallReallyConnected) {
                _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
              }
            },
          ),
          room: ZegoCallRoomEvents(
            onStateChanged: (ZegoUIKitRoomState state) {
              // ✅ No getRoomID() in your version, so only log reason + isRoomLogin
              logI(
                "ROOM_STATE",
                "reason=${state.reason} isRoomLogin=${ZegoUIKit().isRoomLogin}",
              );

              // ✅ We mark "really connected" ONLY when room login succeeds
              if (state.reason == ZegoRoomStateChangedReason.Logined &&
                  _pendingCall) {
                _pendingCall = false;
                _wasCallReallyConnected = true;
                _callStartTime = DateTime.now();
                _notInRoomCount = 0;

                logI(
                  "CONNECTED",
                  "Room Logined -> start billing timer, maxSec=$_maxAllowedSeconds",
                );

                _startCallLimitTimer(); // start limit only after connected
              }
            },
          ),
        ),
        requireConfig: (ZegoCallInvitationData invitationData) {
          logI(
            "CONFIG",
            "type=${invitationData.type} invitees=${invitationData.invitees.length}",
          );
          return invitationData.invitees.length > 1
              ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
              : invitationData.type == ZegoInvitationType.videoCall
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
        },
      );

      if (!mounted) return;
      setState(() => _zegoInitialized = true);

      logI("ZEGO_INIT", "✅ init SUCCESS");
    } catch (e, st) {
      logE("ZEGO_INIT", "❌ init FAILED", e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Call service init failed: ${e.toString().split('\n').first}",
            ),
          ),
        );
      }
    } finally {
      _zegoInitializing = false;
    }
  }

  // ✅ SEND wrapper with logs
  Future<bool> _sendInviteWithLogs({
    required String targetUserID,
    required String targetUserName,
    required bool isVideoCall,
    required int pricePerMin,
  }) async {
    final userVM = context.read<UserViewModel>();
    final myId = (userVM.currentUser?.memberID ?? '').trim();

    final inviteeId = targetUserID.trim();
    final inviteeName = (targetUserName.isEmpty ? "User" : targetUserName)
        .trim();

    logI(
      "SEND",
      "myId=$myId -> inviteeId=$inviteeId name=$inviteeName type=${isVideoCall ? "video" : "voice"} price=$pricePerMin",
    );

    // ✅ Guard 1: empty
    if (inviteeId.isEmpty) {
      logW("SEND", "BLOCKED: inviteeId is empty");
      return false;
    }

    // ✅ Guard 2: self call (this is YOUR current error)
    if (myId.isNotEmpty && inviteeId == myId) {
      logE("SEND", "BLOCKED: trying to call yourself (inviteeId == myId)");
      return false;
    }

    // ✅ Guard 3: service ready
    if (!_zegoInitialized) {
      logW("SEND", "BLOCKED: zego not initialized");
      return false;
    }

    try {
      final callID =
          "${myId}_to_${inviteeId}_${DateTime.now().millisecondsSinceEpoch}";
      final ok = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [
          ZegoCallUser.fromUIKit(
            ZegoUIKitUser(id: inviteeId, name: inviteeName),
          ),
        ],
        isVideoCall: isVideoCall,
        callID: callID,
        customData: '{"price_per_min": $pricePerMin}',
        timeoutSeconds: 60,
      );

      logI("SEND", "result ok=$ok callID=$callID");
      return ok;
    } catch (e, st) {
      logE("SEND", "EXCEPTION", e, st);
      return false;
    }
  }

  void _startInviteTimeoutTimer() {
    _inviteTimeoutTimer?.cancel();
    _inviteTimeoutTimer = Timer(const Duration(seconds: 70), () {
      if (_pendingCall && !_wasCallReallyConnected) {
        logW("INV_TIMEOUT", "No connect within 70s -> reset pending");
        _resetCallTracking();
      }
    });
  }

  void _startCallLimitTimer() {
    _callLimitTimer?.cancel();
    if (_maxAllowedSeconds <= 0) return;

    _callLimitTimer = Timer(Duration(seconds: _maxAllowedSeconds), () {
      logW("LIMIT", "Max time reached -> leaveRoom + handleCallEnd");
      ZegoUIKit().leaveRoom();
      _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Call ended: Time limit reached")),
        );
      }
    });
  }

  void _handleCallEnd(String staffId, bool isVideoCall) {
    // if never connected -> no billing
    if (!_wasCallReallyConnected || _callStartTime == null) {
      logW("BILL", "End without real connection -> no deduction");
      _resetCallTracking();
      return;
    }

    final now = DateTime.now();
    final durationSeconds = now.difference(_callStartTime!).inSeconds;

    if (durationSeconds < 15) {
      logW("BILL", "Call too short ($durationSeconds sec) -> no billing");
      _resetCallTracking();
      return;
    }

    _callLimitTimer?.cancel();
    _inviteTimeoutTimer?.cancel();

    final minutesFraction = durationSeconds / 60.0;
    final spent = (minutesFraction * (_currentCallPricePerMin ?? 0)).ceil();

    final userVM = context.read<UserViewModel>();
    final currentBalance = userVM.currentUser?.coinBalance ?? 0;
    final newBalance = currentBalance - spent;

    userVM.updateUserCoinBalance(
      newBalance,
      staffId,
      spent,
      durationSeconds.toString(),
      isVideoCall ? "video" : "audio",
    );
    userVM.updateLocalCoinBalance(newBalance);

    logI(
      "BILL",
      "ended -> duration=$durationSeconds sec, spent=$spent, remaining=$newBalance",
    );

    _resetCallTracking();
  }

  void _resetCallTracking() {
    _pendingCall = false;
    _callStartTime = null;
    _staffId = null;
    _currentCallPricePerMin = null;
    _isCurrentCallVideo = false;
    _wasCallReallyConnected = false;
    _maxAllowedSeconds = 0;

    _notInRoomCount = 0;
    _callLimitTimer?.cancel();
    _inviteTimeoutTimer?.cancel();
  }

  @override
  void dispose() {
    _callLimitTimer?.cancel();
    _inviteTimeoutTimer?.cancel();
    _periodicCheckTimer?.cancel();

    if (_zegoInitialized) {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel, StaffViewModel>(
      builder: (context, userVM, staffVM, child) {
        final currentUser = userVM.currentUser;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF140810),
                  Color(0xFF3A152A),
                  Color(0xFF140810),
                  Color(0xFF140810),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/Images/bonding.svg",
                          height: 32,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => bondNavigator.newPage(
                            context,
                            page: const WalletScreen(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFcc529f), Color(0xFFf86460)],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  "assets/Images/goldcoin1.png",
                                  height: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${currentUser?.coinBalance ?? 0}.00",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => bondNavigator.newPage(
                            context,
                            page: const ProfileScreen(backPage: true),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                (currentUser?.image != null &&
                                    currentUser!.image!.isNotEmpty)
                                ? NetworkImage(currentUser.image!)
                                : const AssetImage("assets/Images/profile.png")
                                      as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(
                          _zegoInitialized ? Icons.check_circle : Icons.info,
                          color: _zegoInitialized
                              ? Colors.green
                              : Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _zegoInitialized
                              ? "Call service ready"
                              : (_zegoInitializing
                                    ? "Connecting call service..."
                                    : "Call service not ready"),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Staff List
                  Expanded(
                    child: staffVM.isFetchingStaff
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : staffVM.staffFetchError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  staffVM.staffFetchError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: staffVM.fetchStaffDetails,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : staffVM.staffList.isEmpty
                        ? const Center(
                            child: Text(
                              "No staff available",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              try {
                                final userVM2 = context.read<UserViewModel>();
                                await Future.wait([
                                  staffVM.fetchStaffDetails(),
                                  userVM2.fetchUserDetails(),
                                ]);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Refresh failed: ${e.toString()}",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: staffVM.staffList.length,
                              itemBuilder: (context, index) {
                                final staff = staffVM.staffList[index];
                                return _staffProfileCard(staff);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _staffProfileCard(StaffDataProfile staff) {
    final age = _calculateAgeFromDOB(staff.dob ?? '');
    final isOnline = staff.isOnline;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "${staff.name}, ${age ?? '23'}",
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? "Online" : "Offline",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 35,
                    backgroundImage:
                        (staff.image != null && staff.image!.isNotEmpty)
                        ? NetworkImage(staff.image!)
                        : const AssetImage("assets/Images/videocallprofile.png")
                              as ImageProvider,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: staff.areaOfInterest
                      .map(
                        (interest) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Tag(interest.title),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 10),

              AppText(
                "No bio available yet...",
                color: Colors.white,
                fontSize: 15,
                maxLines: 3,
                fontWeight: FontWeight.w500,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _customCallButton(
                      text: "20/min",
                      pricePerMin: 20,
                      isVideoCall: false,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Staff",
                      targetStaffId: staff.id,
                      isTargetOnline: staff.isOnline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _customCallButton(
                      text: "60/min",
                      pricePerMin: 60,
                      isVideoCall: true,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Staff",
                      targetStaffId: staff.id,
                      isTargetOnline: staff.isOnline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customCallButton({
    required String text,
    required int pricePerMin,
    required bool isVideoCall,
    required String targetUserID,
    required String targetUserName,
    required String targetStaffId,
    required bool isTargetOnline,
  }) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final balance = userVM.currentUser?.coinBalance ?? 0;
        if (pricePerMin <= 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () async {
            if (!_zegoInitialized) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Call service not ready yet. Please wait..."),
                ),
              );
              return;
            }

            // ✅ prevent sending to offline to avoid failures
            if (!isTargetOnline) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("User is offline")));
              return;
            }

            // Balance check
            if (balance < pricePerMin) {
              Utils.snackBarErrorMessage("Insufficient balance");
              return;
            }

            // Permissions
            final statuses = await [
              Permission.microphone,
              if (isVideoCall) Permission.camera,
            ].request();

            if (!statuses[Permission.microphone]!.isGranted ||
                (isVideoCall && !statuses[Permission.camera]!.isGranted)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Permissions required")),
              );
              return;
            }

            // Max duration based on balance
            _maxAllowedSeconds = (balance ~/ pricePerMin) * 60;

            // ✅ send with logs
            final success = await _sendInviteWithLogs(
              targetUserID: targetUserID,
              targetUserName: targetUserName,
              isVideoCall: isVideoCall,
              pricePerMin: pricePerMin,
            );

            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to send invitation")),
              );
              return;
            }

            // ✅ mark as pending (DO NOT start billing yet)
            setState(() {
              _pendingCall = true;
              _staffId = targetStaffId;
              _currentCallPricePerMin = pricePerMin;
              _isCurrentCallVideo = isVideoCall;

              _wasCallReallyConnected = false;
              _callStartTime = null;
              _notInRoomCount = 0;
            });

            logI(
              "TRACK",
              "Pending call started -> target=${targetUserID.trim()} staffID=$targetStaffId price=$pricePerMin maxSec=$_maxAllowedSeconds",
            );

            _startInviteTimeoutTimer(); // clears if not accepted/connected
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF9251d0), Color(0xFFf56463)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/Images/goldcoin1.png", height: 20),
                const SizedBox(width: 4),
                AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
                const SizedBox(width: 6),
                Icon(
                  isVideoCall ? Icons.video_call : Icons.call,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int? _calculateAgeFromDOB(String dob) {
    if (dob.isEmpty) return null;
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return null;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFF45333c), Color(0xFF4a263c)],
        ),
        border: Border.all(color: const Color(0xFF5a3c4e)),
      ),
      child: AppText(
        text,
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}


/*
// lib/BondingScreens/HomeScreen/HomeScreen.dart

import 'dart:async';
import 'dart:ui';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Socket.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/Model/VerifyOtpModel.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _zegoInitialized = false;
  bool _isZimConnected = false;

  // ─── Call Tracking ──────────────────────────────────────────────────────
  DateTime? _callStartTime;
  String? _currentCallTargetID;
  String? _staffId;
  int? _currentCallPricePerMin;
  bool _isCurrentCallVideo = false;
  bool _wasCallReallyConnected =
      false; // NEW: tracks if call was accepted & connected
  Timer? _callTimer;
  Timer? _periodicCheckTimer;
  int _notInRoomCount = 0;
  final socketService = SocketService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userVM = context.read<UserViewModel>();
      await userVM.fetchUserDetails();

      final user = userVM.currentUser;

      if (user != null && user.memberID.isNotEmpty) {
        debugPrint(
          "User fetched → memberID: ${user.memberID}, name: ${user.name}",
        );
        await _connectZimUser(user);
      } else {
        debugPrint("No valid user after fetchUserDetails()");
      }

      context.read<StaffViewModel>().fetchStaffDetails();
      final staff = context.read<StaffViewModel>();

      final staffVM = context.read<StaffViewModel>();

      await staffVM.fetchStaffDetails();

      // 🔥 connect socket using first staff (example)
      if (staffVM.staffList.isNotEmpty) {
        final staffID = staffVM.staffList.first.memberID;

        print("Connecting socket as staff → $staffID");

        socketService.connectStaff(staffID);

        socketService.listenStaffList((data) {
          staffVM.updateStaffPresence(data);
        });
      }
    });

    // Safety net: periodic check (only for detecting stuck states)
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_callStartTime == null) return;

      if (!ZegoUIKit().isRoomLogin) {
        _notInRoomCount++;
        debugPrint("Not in room detected ($_notInRoomCount / 5)");
        if (_notInRoomCount >= 5 && _wasCallReallyConnected) {
          debugPrint("Consecutive not-in-room after connected → end call");
          _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
        }
      } else {
        _notInRoomCount = 0;
      }
    });
  }

  Future<void> _connectZimUser(UserProfile? user) async {
    if (user == null || _isZimConnected) return;

    try {
      debugPrint("→ Starting ZIM connect for ID: ${user.memberID}");

      await ZIMKit().connectUser(
        id: user.memberID,
        name: user.name ?? "User_${user.memberID}",
        avatarUrl: user.image ?? "",
      );
      setState(() => _isZimConnected = true);
      debugPrint("→ ZIMKit login SUCCESS for ${user.memberID}");
    } catch (e, stackTrace) {
      debugPrint("→ ZIMKit login FAILED: $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Chat connection failed: ${e.toString().split('\n').first}",
            ),
          ),
        );
      }
    }
  }

  void _handleCallEnd(String staffId, bool isVideoCall) {
    if (_callStartTime == null) return;

    final now = DateTime.now();
    final durationSeconds = now.difference(_callStartTime!).inSeconds;

    // ─── Guards: skip billing if call was never really connected or too short ───────
    if (!_wasCallReallyConnected) {
      debugPrint("Call ended without real connection → no deduction");
      _resetCallTracking();
      return;
    }

    if (durationSeconds < 15) {
      debugPrint(
        "Call too short ($durationSeconds s) → likely no meaningful conversation → no billing",
      );
      _resetCallTracking();
      return;
    }

    // ─── Real attended call ───────────────────────────────────────
    _callTimer?.cancel();

    // Pro-rated calculation
    final minutesFraction = durationSeconds / 60.0;
    final spent = (minutesFraction * (_currentCallPricePerMin ?? 0)).ceil();

    final userVM = context.read<UserViewModel>();
    final currentBalance = userVM.currentUser?.coinBalance ?? 0;
    final newBalance = currentBalance - spent;

    // Update backend + local
    userVM.updateUserCoinBalance(
      newBalance,
      staffId,
      spent,
      durationSeconds.toString(),
      isVideoCall ? "video" : "audio",
    );
    userVM.updateLocalCoinBalance(newBalance);

    // Show message
    final message =
        """
Call ended!
Duration: ${durationSeconds}s (${durationSeconds ~/ 60} min ${durationSeconds % 60}s)
Spent: $spent coins
Remaining: $newBalance
    """;
    // Utils.snackBar(message.trim());
    print("message?????????? ${message.trim()}");

    _resetCallTracking();
  }

  void _resetCallTracking() {
    _callStartTime = null;
    _currentCallTargetID = null;
    _staffId = null;
    _currentCallPricePerMin = null;
    _isCurrentCallVideo = false;
    _wasCallReallyConnected = false;
    _notInRoomCount = 0;
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _periodicCheckTimer?.cancel();
    if (_zegoInitialized) {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel, StaffViewModel>(
      builder: (context, userVM, staffVM, child) {
        final currentUser = userVM.currentUser;

        if (currentUser != null && !_zegoInitialized && !userVM.isLoading) {
          final userID = currentUser.memberID;
          final userName = currentUser.name ?? "User";

          ZegoUIKitPrebuiltCallInvitationService().init(
            appID: 467997506,
            appSign:
                "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",
            userID: userID,
            userName: userName,
            plugins: [ZegoUIKitSignalingPlugin()],
            notificationConfig: ZegoCallInvitationNotificationConfig(
              androidNotificationConfig: ZegoAndroidNotificationConfig(
                channelID: "ZegoUIKit",
                channelName: "Call Notifications",
                sound: "zego_incoming",
                icon: "notification_icon",
              ),
              iOSNotificationConfig: ZegoIOSNotificationConfig(
                isSandboxEnvironment: false,
              ),
            ),
            events: ZegoUIKitPrebuiltCallEvents(
              // Called when call ends (local/remote hang up, timeout, kick out, etc.)
              onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
                debugPrint("Call ended → reason: ${event.reason.name}");
                if (_callStartTime != null) {
                  _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
                  print("sdcs");
                }
                defaultAction
                    .call(); // Let ZEGO handle default navigation (pop call page)
              },

              // Detect remote user leave (alternative way to trigger end)
              user: ZegoCallUserEvents(
                onLeave: (user) {
                  debugPrint("Remote user left: ${user.id} → ending call");
                  if (_callStartTime != null) {
                    _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
                  }
                },
              ),

              // Room state change (this replaces your old onCallStateChanged)
              room: ZegoCallRoomEvents(
                onStateChanged: (ZegoUIKitRoomState state) {
                  debugPrint("Room state changed → reason: ${state.reason}");
                  if (state.reason == ZegoRoomStateChangedReason.Logined &&
                      _callStartTime != null) {
                    // Assuming "connected" ≈ logged in successfully after join
                    debugPrint("Room connected → real conversation started");
                    setState(() => _wasCallReallyConnected = true);
                  }
                },
              ),
            ),
            requireConfig: (ZegoCallInvitationData invitationData) {
              return invitationData.invitees.length > 1
                  ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                  : invitationData.type == ZegoInvitationType.videoCall
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
            },
          );

          _zegoInitialized = true;
        }

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF140810),
                  Color(0xFF3A152A),
                  Color(0xFF140810),
                  Color(0xFF140810),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          "assets/Images/bonding.svg",
                          height: 32,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => bondNavigator.newPage(
                            context,
                            page: const WalletScreen(),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFcc529f), Color(0xFFf86460)],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  "assets/Images/goldcoin1.png",
                                  height: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${currentUser?.coinBalance ?? 0}.00",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => bondNavigator.newPage(
                            context,
                            page: const ProfileScreen(backPage: true),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage:
                                (currentUser?.image != null &&
                                    currentUser!.image!.isNotEmpty)
                                ? NetworkImage(currentUser.image!)
                                : const AssetImage("assets/Images/profile.png")
                                      as ImageProvider,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF35272d),
                                Color(0xFF3e2534),
                                Color(0xFF3c1b2f),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.8,
                            ),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search by “name, call topics”',
                              hintStyle: const TextStyle(
                                color: Color(0xFFc7c7cc),
                                fontSize: 16,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.white70,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Staff List
                  Expanded(
                    child: staffVM.isFetchingStaff
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : staffVM.staffFetchError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  staffVM.staffFetchError!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: staffVM.fetchStaffDetails,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : staffVM.staffList.isEmpty
                        ? const Center(
                            child: Text(
                              "No staff available",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              try {
                                final userVM = context.read<UserViewModel>();
                                await Future.wait([
                                  staffVM.fetchStaffDetails(),
                                  userVM.fetchUserDetails(),
                                ]);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Refresh failed: ${e.toString()}",
                                      ),
                                    ),
                                  );
                                }
                              }
                            },

                            child: Builder(
                              builder: (BuildContext context) {
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: staffVM.staffList.length,
                                  itemBuilder: (context, index) {
                                    final staff = staffVM.staffList[index];
                                    return _staffProfileCard(staff);
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _staffProfileCard(StaffDataProfile staff) {
    final age = _calculateAgeFromDOB(staff.dob ?? '');
    print("/////${staff.dob ?? ""}");
    final isOnline = staff.isOnline;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "${staff.name}, ${age ?? '23'}",
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? "Online" : "Offline",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 35,
                    backgroundImage:
                        (staff.image != null && staff.image!.isNotEmpty)
                        ? NetworkImage(staff.image!)
                        : const AssetImage("assets/Images/videocallprofile.png")
                              as ImageProvider,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: staff.areaOfInterest
                      .map(
                        (interest) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Tag(interest.title),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 10),

              AppText(
                "No bio available yet...",
                color: Colors.white,
                fontSize: 15,
                maxLines: 3,
                fontWeight: FontWeight.w500,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _customCallButton(
                      text: "20/min",
                      pricePerMin: 20,
                      isVideoCall: false,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Staff",
                      targetStaffId: staff.id,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _customCallButton(
                      text: "60/min",
                      pricePerMin: 60,
                      isVideoCall: true,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Staff",
                      targetStaffId: staff.id,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customCallButton({
    required String text,
    required int pricePerMin,
    required bool isVideoCall,
    required String targetUserID,
    required String targetUserName,
    required String targetStaffId,
  }) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final currentUser = userVM.currentUser;
        final balance = currentUser?.coinBalance ?? 0;

        if (pricePerMin <= 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () async {
            // Permissions
            final statuses = await [
              Permission.microphone,
              if (isVideoCall) Permission.camera,
            ].request();

            if (!statuses[Permission.microphone]!.isGranted ||
                (isVideoCall && !statuses[Permission.camera]!.isGranted)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Permissions required")),
              );
              return;
            }

            // Balance check
            if (balance < pricePerMin) {
              Utils.snackBarErrorMessage("Insufficient balance");
              return;
            }

            // Max duration
            final maxMinutes = balance ~/ pricePerMin;
            final maxSeconds = maxMinutes * 60;

            // Send invitation
            final success = await ZegoUIKitPrebuiltCallInvitationService().send(
              invitees: [
                ZegoCallUser.fromUIKit(
                  ZegoUIKitUser(id: targetUserID, name: targetUserName),
                ),
              ],
              isVideoCall: isVideoCall,
              callID:
                  "${targetUserID}_${DateTime.now().millisecondsSinceEpoch}",
              customData: '{"price_per_min": $pricePerMin}',
              timeoutSeconds: 60,
            );

            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to send invitation")),
              );
              return;
            }

            // Start tracking
            setState(() {
              _callStartTime = DateTime.now();
              _currentCallTargetID = targetUserID;
              _staffId = targetStaffId;
              _currentCallPricePerMin = pricePerMin;
              _isCurrentCallVideo = isVideoCall;
              _wasCallReallyConnected =
                  false; // Reset - will be set when connected
            });

            debugPrint(
              "Call invitation sent → tracking started | Target: $targetUserID | Staff ID: $targetStaffId | Price: $pricePerMin/min | Max: $maxSeconds sec",
            );

            // Force end after max time (safety)
            _callTimer = Timer(Duration(seconds: maxSeconds), () {
              ZegoUIKit().leaveRoom();
              _handleCallEnd(targetStaffId, isVideoCall);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Call ended: Time limit reached")),
              );
            });
          },
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF9251d0), Color(0xFFf56463)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/Images/goldcoin1.png", height: 20),
                const SizedBox(width: 4),
                AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
                const SizedBox(width: 6),
                Icon(
                  isVideoCall ? Icons.video_call : Icons.call,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int? _calculateAgeFromDOB(String dob) {
    print("??????$dob");
    if (dob.isEmpty) return null;
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return null;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFF45333c), Color(0xFF4a263c)],
        ),
        border: Border.all(color: const Color(0xFF5a3c4e)),
      ),
      child: AppText(
        text,
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
*/
