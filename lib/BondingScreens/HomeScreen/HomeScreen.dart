// lib/BondingScreens/HomeScreen/HomeScreen.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/PlatformViews/home_android_body.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/PlatformViews/home_ios_body.dart';
import 'package:bonding_app/Bonding_Utils/Call/ios_call_approval_store.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

import 'package:logger/logger.dart';

const int _zegoAppId = 2073142303;
const String _zegoAppSign =
    'cb2e20977165308bab891c28a97e12100ed429d9469846955090e008435ad3b1';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Logger
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _zegoInitialized = false;
  bool _zegoInitializing = false;
  bool _isZimConnected = false;

  // âœ… NEW: local ready flag (prevents package crash)
  bool _zegoLocalReady = false;
  String _zegoLocalId = "";

  // â”€â”€â”€ Call Tracking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _pendingCall = false;
  DateTime? _callStartTime;
  String? _staffId;
  int? _currentCallPricePerMin;
  bool _isCurrentCallVideo = false;
  bool _wasCallReallyConnected = false;

  int _maxAllowedSeconds = 0;
  Timer? _callLimitTimer;
  Timer? _inviteTimeoutTimer;
  Timer? _periodicCheckTimer;
  int _notInRoomCount = 0;

  final socketService = SocketService();
  StreamSubscription? _homeReceiveSub;

  Set<String> _callApprovedStaffIds = <String>{};

  Future<void> _showInfoPopup({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9251D0), Color(0xFFF56463)],
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        // keep dialog from becoming too tall, but allow full text via scroll
                        maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          message,
                          softWrap: true,
                          maxLines: null,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshCallApprovals() async {
    try {
      final set = await IosCallApprovalStore.load();
      if (!mounted) return;
      setState(() => _callApprovedStaffIds = set);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    // Listen globally so when staff replies (socket) we can unlock call/video on HomeScreen.
    _homeReceiveSub ??= socketService.receiveMessageStream.listen((data) async {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      final senderRole = (m["senderRole"] ?? "")
          .toString()
          .toLowerCase()
          .trim();
      if (senderRole != "staff") return;

      final staffMongoId = (m["staffId"] ?? "").toString().trim();
      if (staffMongoId.isEmpty) return;

      await IosCallApprovalStore.markApproved(staffMongoId);
      await _refreshCallApprovals();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshCallApprovals();
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

        // ✅ Ensure socket connects on HomeScreen itself (not only when opening chat)
        try {
          logI("SOCKET", "HomeScreen -> connectUserRegister()");
          await socketService.connectUserRegister();
          logI(
            "SOCKET",
            "HomeScreen socket connected=${socketService.isConnected} snapshot=${socketService.debugSnapshot()}",
          );
        } catch (e) {
          logW("SOCKET", "HomeScreen socket connect failed: $e");
        }
      } else {
        logW("INIT", "No valid user after fetchUserDetails()");
      }

      final staffVM = context.read<StaffViewModel>();
      await staffVM.fetchStaffDetails();

      if (staffVM.staffList.isNotEmpty) {
        final staffID = staffVM.staffList.first.memberID;
        logI("SOCKET", "Connecting socket as staff -> $staffID");

        // socketService.connectStaff(staffID);
        socketService.listenStaffList((data) {
          staffVM.updateStaffPresence(data);
        });

        // Ask for initial list once socket is up (if not connected, it will no-op)
        socketService.requestStaffList();
      }
    });

    // Safety net: if call connected but room drops, end after 5 checks
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
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

  // âœ… Your version supports getLocalUser()
  String _getZegoLocalUserIDSafe() {
    try {
      return ZegoUIKit().getLocalUser().id.trim();
    } catch (_) {
      return "";
    }
  }

  Future<void> _waitForZegoLocalReady() async {
    for (int i = 0; i < 30; i++) {
      final id = _getZegoLocalUserIDSafe();
      if (id.isNotEmpty) {
        _zegoLocalId = id;
        if (mounted) setState(() => _zegoLocalReady = true);
        logI("ZEGO_LOCAL", "âœ… local user ready -> $_zegoLocalId");
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _zegoLocalId = "";
    if (mounted) setState(() => _zegoLocalReady = false);
    logW(
      "ZEGO_LOCAL",
      "âš ï¸ local user NOT ready yet. Will block send() until ready.",
    );
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

  Future<void> _initZegoCallInvitation(UserProfile user) async {
    if (_zegoInitialized || _zegoInitializing) return;

    final plugin = ZegoUIKitSignalingPlugin();

    try {
      _zegoInitializing = true;
      logI("ZEGO_INIT", "init start -> user=${user.memberID}");

      await ZegoUIKitPrebuiltCallInvitationService().init(
        plugins: [plugin],
        appID: _zegoAppId,
        appSign: _zegoAppSign,
        userID: user.memberID.trim(),
        userName: (user.name ?? "User").trim(),
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
          onCallEnd: (event, defaultAction) {
            logW(
              "CALL_END",
              "reason=${event.reason.name} pending=$_pendingCall connected=$_wasCallReallyConnected",
            );
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
            onStateChanged: (state) {
              logI(
                "ROOM_STATE",
                "reason=${state.reason} isRoomLogin=${ZegoUIKit().isRoomLogin}",
              );

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
                _startCallLimitTimer();
              }
            },
          ),
        ),
        requireConfig: (invitationData) {
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

      // âœ… CRITICAL: wait for local user id ready (prevents _loginUser null crash)
      await _waitForZegoLocalReady();

      if (!mounted) return;
      setState(() => _zegoInitialized = true);

      logI(
        "ZEGO_INIT",
        "âœ… init SUCCESS (localReady=$_zegoLocalReady localId=$_zegoLocalId)",
      );
    } catch (e, st) {
      logE("ZEGO_INIT", "âŒ init FAILED", e, st);
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

  Future<bool> _sendInviteWithLogs({
    required String targetUserID,
    required String targetUserName,
    required bool isVideoCall,
    required int pricePerMin,
  }) async {
    final userVM = context.read<UserViewModel>();
    final myVmId = (userVM.currentUser?.memberID ?? '').trim();

    final inviteeId = targetUserID.trim();
    final inviteeName = (targetUserName.isEmpty ? "User" : targetUserName)
        .trim();

    // refresh local status
    final zegoLocal = _getZegoLocalUserIDSafe();
    if (zegoLocal.isNotEmpty) {
      _zegoLocalId = zegoLocal;
      if (!_zegoLocalReady && mounted) setState(() => _zegoLocalReady = true);
    }

    logI(
      "SEND",
      "vmId=$myVmId zegoLocal=$_zegoLocalId ready=$_zegoLocalReady -> inviteeId=$inviteeId name=$inviteeName "
          "type=${isVideoCall ? "video" : "voice"} price=$pricePerMin",
    );

    if (inviteeId.isEmpty) {
      logW("SEND", "BLOCKED: inviteeId empty");
      return false;
    }

    if (!_zegoInitialized) {
      logW("SEND", "BLOCKED: zego not initialized");
      return false;
    }

    // âœ… THIS is the important guard to avoid package crash
    if (_zegoLocalId.isEmpty) {
      logW(
        "SEND",
        "BLOCKED: ZEGO local user not ready yet (would crash package)",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Call service still connecting. Try again."),
          ),
        );
      }
      return false;
    }

    // self-call protections
    if (inviteeId == myVmId || inviteeId == _zegoLocalId) {
      logE("SEND", "BLOCKED: trying to call yourself");
      return false;
    }

    try {
      final callID =
          "${_zegoLocalId}_to_${inviteeId}_${DateTime.now().millisecondsSinceEpoch}";

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
    if (!_wasCallReallyConnected || _callStartTime == null) {
      logW("BILL", "End without real connection -> no deduction");
      _resetCallTracking();
      return;
    }

    final durationSeconds = DateTime.now()
        .difference(_callStartTime!)
        .inSeconds;

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
    _homeReceiveSub?.cancel();
    // socketService.removeStaffListListener();

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
        final ready = _zegoInitialized && _zegoLocalId.isNotEmpty;
        final isIOS = !kIsWeb && Platform.isIOS;

        final homeBody = isIOS
            ? HomeIosBody(
                userVM: userVM,
                staffVM: staffVM,
                buildCard: (ctx, staff) =>
                    _profileCard(ctx, staff, ready, isIOS: true),
              )
            : HomeAndroidBody(
                userVM: userVM,
                staffVM: staffVM,
                ready: ready,
                zegoInitializing: _zegoInitializing,
                buildCard: (ctx, staff) =>
                    _profileCard(ctx, staff, ready, isIOS: false),
              );

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: Apptheme.backgroundGradient,
            ),
            child: SafeArea(child: homeBody),
          ),
        );
      },
    );
  }

  Widget _staffProfileCard(StaffDataProfile staff, bool ready) {
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _customCallButton(
                      enabled: ready,
                      text: "${staff.audioCallRatePerMinute}/min",
                      pricePerMin: staff.audioCallRatePerMinute,
                      isVideoCall: false,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Women",
                      targetStaffId: staff.id,
                      isTargetOnline: staff.isOnline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _customCallButton(
                      enabled: ready,
                      text: "${staff.videoCallRatePerMinute}/min",
                      pricePerMin: staff.videoCallRatePerMinute,
                      isVideoCall: true,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Women",
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

  Widget _profileCard(
    BuildContext context,
    StaffDataProfile staff,
    bool ready, {
    bool isIOS = false,
  }) {
    final age = _calculateAgeFromDOB(staff.dob ?? '');
    final isOnline = staff.isOnline;
    final callApproved =
        (staff.callEnabled ?? _callApprovedStaffIds.contains(staff.id));
    final staffHeroTag =
        "staff-media-${staff.id.isNotEmpty ? staff.id : staff.name}";
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
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media (tap for full preview)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _TappableMediaBanner(
                  height: 170,
                  name: staff.name,
                  imageUrl: staff.image,
                  heroTag: staffHeroTag,
                ),
              ),

              const SizedBox(height: 12),

              // Name + status
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      "${staff.name.isNotEmpty ? staff.name : 'Unknown'}, ${age ?? '23'}",
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withOpacity(0.28),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Tags / Interests
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: staff.areaOfInterest
                      .map(
                        (interest) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Tag(interest.title ?? ''),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 10),

              // Bio / Description
              AppText(
                (staff.bio != null && staff.bio!.trim().isNotEmpty)
                    ? staff.bio!.trim()
                    : "Helping you navigate life with clarity and care...",
                color: Colors.white,
                fontSize: 15,
                maxLines: 3,
                fontWeight: FontWeight.w500,
              ),

              const SizedBox(height: 14),

              if (isIOS)
                _iosChatRow(context, staff)
              else
                Row(
                  children: [
                    Expanded(
                      child: _customCallButton(
                        enabled: ready && callApproved,
                        disabledMessage: !ready
                            ? "Call service still connecting, try again."
                            : "Chat reply needed to enable call.",
                        text: "${staff.audioCallRatePerMinute}/min",
                        pricePerMin: staff.audioCallRatePerMinute,
                        isVideoCall: false,
                        targetUserID: staff.memberID,
                        targetUserName: staff.name ?? "Women",
                        targetStaffId: staff.id,
                        isTargetOnline: staff.isOnline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _customCallButton(
                        enabled: ready && callApproved,
                        disabledMessage: !ready
                            ? "Call service still connecting, try again."
                            : "Chat reply needed to enable call.",
                        text: "${staff.videoCallRatePerMinute}/min",
                        pricePerMin: staff.videoCallRatePerMinute,
                        isVideoCall: true,
                        targetUserID: staff.memberID,
                        targetUserName: staff.name ?? "Women",
                        targetStaffId: staff.id,
                        isTargetOnline: staff.isOnline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _openStaffChat(context, staff),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            "assets/Images/chaticon.png",
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              // Row(
              //   children: [
              //     Expanded(
              //       flex: 2,
              //       child: _actionButton(
              //         img: "assets/Images/goldcoin1.png",
              //         text: "20/min",
              //         icon: Icons.call,
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       flex: 2,
              //       child: _actionButton(
              //         img: "assets/Images/goldcoin1.png",
              //         text: "60/min",
              //         icon: Icons.video_call,
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //
              //     // Inside _profileCard â†’ the Chat button GestureDetector
              //     Expanded(
              //       child: GestureDetector(
              //         onTap: () async {
              //           final userVM = Provider.of<UserViewModel>(context, listen: false);
              //           final currentUser = userVM.currentUser;
              //           if (currentUser == null) return;
              //
              //           // (Your Zego check can stay if needed)
              //           final connected = await ZimConnectionService.ensureConnected(
              //             context,
              //             userId: currentUser.memberID,
              //             userName: currentUser.name ?? "User",
              //           );
              //           if (!connected) return;
              //
              //           final staffId = staff.id;          // staff mongo _id
              //           final userId = currentUser.id;     // user mongo _id
              //           final staffName = staff.name ?? "Staff";
              //
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder: (_) => ChangeNotifierProvider<ChatProviderVm>(
              //                 create: (_) => ChatProviderVm(
              //                   repo: ChatRepository(NetworkApiService()),
              //                 )..initChat(staffId: staffId, userId: userId,isStaff: false), // âœ… history + socket init
              //                 child: ChatDetailScreen(
              //                   isBlocked: false,
              //                   staffImage: staff.image ?? '',
              //                   staffId: staffId,
              //                   staffName: staffName,
              //                   userId: userId,
              //                 ),
              //               ),
              //             ),
              //           );
              //         },
              //
              //
              //         child: Center(
              //           child: Image.asset("assets/Images/chaticon.png"),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showConnectionPreview(
    BuildContext context,
    StaffDataProfile staff,
  ) async {
    final age = _calculateAgeFromDOB(staff.dob ?? '');
    final name = staff.name.trim().isNotEmpty ? staff.name.trim() : "Profile";
    final bio = (staff.bio ?? '').trim().isNotEmpty
        ? staff.bio!.trim()
        : "This profile is available for a moderated one-to-one chat.";
    final interests = staff.areaOfInterest
        .map((item) => (item.title ?? '').trim())
        .where((title) => title.isNotEmpty)
        .take(4)
        .toList();

    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF21131B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage:
                          (staff.image != null && staff.image!.isNotEmpty)
                          ? NetworkImage(staff.image!)
                          : const AssetImage(
                                  "assets/Images/videocallprofile.png",
                                )
                                as ImageProvider,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            age == null ? name : "$name, $age",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: staff.isOnline
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                staff.isOnline ? "Online" : "Offline",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "Review this profile before connecting. You can start the chat, decline, or skip this profile.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map(
                          (title) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, "skip"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Skip"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, "decline"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Decline"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, "accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE95BA8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Start Chat",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return choice == "accept";
  }

  Future<void> _openStaffChat(
    BuildContext context,
    StaffDataProfile staff,
  ) async {
    final accepted = await _showConnectionPreview(context, staff);
    if (!accepted || !mounted || !context.mounted) return;

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final currentUser = userVM.currentUser;
    if (currentUser == null) return;

    final connected = await ZimConnectionService.ensureConnected(
      context,
      userId: currentUser.memberID,
      userName: currentUser.name ?? "User",
    );
    if (!connected || !mounted || !context.mounted) return;

    final staffId = staff.id;
    final userId = currentUser.id;
    final staffName = staff.name.trim().isNotEmpty ? staff.name : "Profile";

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ChatProviderVm>(
          create: (_) =>
              ChatProviderVm(repo: ChatRepository(NetworkApiService()))
                ..initChat(staffId: staffId, userId: userId, isStaff: false),
          child: ChatDetailScreen(
            isBlocked: false,
            staffImage: staff.image ?? '',
            staffId: staffId,
            staffName: staffName,
            userId: userId,
            staffMemberId: staff.memberID,
            audioRatePerMin: staff.audioCallRatePerMinute,
            videoRatePerMin: staff.videoCallRatePerMinute,
          ),
        ),
      ),
    );

    if (!mounted || !context.mounted) return;

    try {
      await context.read<StaffViewModel>().fetchStaffDetails();
    } catch (_) {}
    await _refreshCallApprovals();
  }

  Widget _iosChatRow(BuildContext context, StaffDataProfile staff) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _openStaffChat(context, staff),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: Apptheme.buttonGradient,
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Chat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _androidActionRow(
    BuildContext context,
    StaffDataProfile staff, {
    required bool ready,
    required bool callApproved,
  }) {
    final disabledMessage = !ready
        ? "Call service still connecting, try again."
        : "Chat reply needed to enable call.";

    return Row(
      children: [
        Expanded(
          child: _customCallButton(
            enabled: ready && callApproved,
            disabledMessage: disabledMessage,
            text: "${staff.audioCallRatePerMinute}/min",
            pricePerMin: staff.audioCallRatePerMinute,
            isVideoCall: false,
            targetUserID: staff.memberID,
            targetUserName: staff.name ?? "Women",
            targetStaffId: staff.id,
            isTargetOnline: staff.isOnline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _customCallButton(
            enabled: ready && callApproved,
            disabledMessage: disabledMessage,
            text: "${staff.videoCallRatePerMinute}/min",
            pricePerMin: staff.videoCallRatePerMinute,
            isVideoCall: true,
            targetUserID: staff.memberID,
            targetUserName: staff.name ?? "Women",
            targetStaffId: staff.id,
            isTargetOnline: staff.isOnline,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _openStaffChat(context, staff),
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Center(
              child: Image.asset(
                "assets/Images/chaticon.png",
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customCallButton({
    required bool enabled,
    String? disabledMessage,
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

        return GestureDetector(
          onTap: () async {
            if (!enabled) {
              final msg =
                  (disabledMessage ??
                          "Call service still connecting, try again.")
                      .trim();

              final isChatLock = msg.toLowerCase().contains("chat reply");
              await _showInfoPopup(
                context: context,
                title: isChatLock ? "Call is locked" : "Please wait",
                message: isChatLock
                    ? "To enable audio or video calls, please send a chat message first and wait for her reply.\n\nOnce she replies, the call buttons will unlock automatically on this screen."
                    : msg,
              );
              return;
            }

            if (!isTargetOnline) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("User is offline")));
              return;
            }

            if (balance < pricePerMin) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WalletScreen()),
              );
              Utils.snackBarErrorMessage("Insufficient balance");

              return;
            }

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

            _maxAllowedSeconds = (balance ~/ pricePerMin) * 60;

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
              "Pending call started -> target=$targetUserID staffID=$targetStaffId",
            );
            _startInviteTimeoutTimer();
          },
          child: Opacity(
            opacity: enabled ? 1.0 : 0.55,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/Images/goldcoin1.png", height: 20),
                  const SizedBox(width: 4),
                  AppText(
                    text,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isVideoCall ? Icons.video_call : Icons.call,
                    color: Colors.white,
                  ),
                ],
              ),
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

class _TappableAvatar extends StatelessWidget {
  final double radius;
  final String name;
  final String? imageUrl;
  final String heroTag;

  const _TappableAvatar({
    required this.radius,
    required this.name,
    required this.imageUrl,
    required this.heroTag,
  });

  static String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    return trimmed.substring(0, 1).toUpperCase();
  }

  static bool _isValidNetworkImageUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!uri.isAbsolute) return false;
    if (uri.scheme != "http" && uri.scheme != "https") return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _isValidNetworkImageUrl(imageUrl);
    final size = radius * 2;
    final fallback = _AvatarFallback(size: size, initial: _initial(name));

    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasImage
            ? Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      fallback,
                      Center(
                        child: SizedBox(
                          width: radius,
                          height: radius,
                          child: AppLoadingIndicator(
                            radius: 10,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                errorBuilder: (context, error, stackTrace) => fallback,
              )
            : fallback,
      ),
    );

    final hero = Hero(
      tag: heroTag,
      child: Material(type: MaterialType.transparency, child: avatar),
    );

    if (!hasImage) return hero;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return _AvatarPreviewPage(
                imageUrl: imageUrl!.trim(),
                heroTag: heroTag,
                title: name,
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
      child: hero,
    );
  }
}

class _TappableMediaBanner extends StatelessWidget {
  final double height;
  final String? name;
  final String? imageUrl;
  final String heroTag;

  const _TappableMediaBanner({
    required this.height,
    required this.name,
    required this.imageUrl,
    required this.heroTag,
  });

  static String _initial(String? name) {
    final trimmed = (name ?? "").trim();
    if (trimmed.isEmpty) return "?";
    return trimmed.substring(0, 1).toUpperCase();
  }

  static bool _isValidNetworkImageUrl(String? url) {
    if (url == null) return false;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!uri.isAbsolute) return false;
    if (uri.scheme != "http" && uri.scheme != "https") return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _isValidNetworkImageUrl(imageUrl);
    final rawName = (name ?? "").trim();
    final safeName = rawName.isEmpty ? "User" : rawName;
    final initial = _initial(safeName);

    final banner = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl!.trim(),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return _MediaFallback(initial: initial);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _MediaFallback(initial: initial),
                      Center(
                        child: AppLoadingIndicator(
                          radius: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            _MediaFallback(initial: initial),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.38)],
              ),
            ),
          ),
          // Name overlay removed (as requested)
        ],
      ),
    );

    if (!hasImage) return banner;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) {
              return _AvatarPreviewPage(
                imageUrl: imageUrl!.trim(),
                heroTag: heroTag,
                title: safeName,
              );
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      },
      child: banner,
    );
  }
}

class _MediaFallback extends StatelessWidget {
  final String initial;

  const _MediaFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1c2b1b), Color(0xFF0f141e)],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.20,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 120,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final double size;
  final String initial;

  const _AvatarFallback({required this.size, required this.initial});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2b2f3a), Color(0xFF15161c)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w700,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}

class _AvatarPreviewPage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String title;

  const _AvatarPreviewPage({
    required this.imageUrl,
    required this.heroTag,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        "Image failed to load",
                        style: TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

//
// // lib/BondingScreens/HomeScreen/HomeScreen.dart
//
// import 'dart:async';
// import 'dart:ui';
//
// import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/Socket.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
// import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
// import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
// import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
// import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
// import 'package:bonding_app/Socket/socket_service.dart';
// import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
//
// import 'package:zego_uikit/zego_uikit.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
//
// // âœ… logger
// import 'package:logger/logger.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   // Logger
//   // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   final Logger _log = Logger(
//     printer: PrettyPrinter(
//       methodCount: 0,
//       errorMethodCount: 8,
//       lineLength: 120,
//       colors: true,
//       printEmojis: true,
//       printTime: true,
//     ),
//   );
//
//   void logI(String tag, String msg) => _log.i("[$tag] $msg");
//   void logW(String tag, String msg) => _log.w("[$tag] $msg");
//   void logE(String tag, String msg, [Object? e, StackTrace? st]) =>
//       _log.e("[$tag] $msg", error: e, stackTrace: st);
//
//   // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   bool _zegoInitialized = false;
//   bool _zegoInitializing = false;
//   bool _isZimConnected = false;
//
//   // â”€â”€â”€ Call Tracking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   bool _pendingCall = false; // âœ… NEW: send() happened, waiting for room login
//   DateTime? _callStartTime; // âœ… now set only when room is logged-in
//   String? _staffId;
//   int? _currentCallPricePerMin;
//   bool _isCurrentCallVideo = false;
//   bool _wasCallReallyConnected = false;
//
//   int _maxAllowedSeconds = 0; // based on balance
//   Timer? _callLimitTimer; // ends call when max reached
//   Timer? _inviteTimeoutTimer; // clears pending if not accepted
//   Timer? _periodicCheckTimer;
//   int _notInRoomCount = 0;
//
//   final socketService = SocketService();
//
//   // NOTE:
//   // Your versions do NOT expose `connectionState` or invitation events.
//   // So we keep logs based on init/send/room login states only.
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final userVM = context.read<UserViewModel>();
//       await userVM.fetchUserDetails();
//
//       final user = userVM.currentUser;
//
//       if (user != null && user.memberID.isNotEmpty) {
//         logI(
//           "INIT",
//           "User fetched -> memberID=${user.memberID}, name=${user.name}",
//         );
//
//         await _connectZimUser(user);
//         await _initZegoCallInvitation(user);
//       } else {
//         logW("INIT", "No valid user after fetchUserDetails()");
//       }
//
//       final staffVM = context.read<StaffViewModel>();
//       await staffVM.fetchStaffDetails();
//
//       if (staffVM.staffList.isNotEmpty) {
//         final staffID = staffVM.staffList.first.memberID;
//         logI("SOCKET", "Connecting socket as staff -> $staffID");
//
//         socketService.connectStaff(staffID);
//         socketService.listenStaffList((data) {
//           staffVM.updateStaffPresence(data);
//         });
//       }
//     });
//
//     // âœ… Safety net: if call was connected and we suddenly leave room, end call after 5 checks
//     _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (!_wasCallReallyConnected) return;
//
//       if (!ZegoUIKit().isRoomLogin) {
//         _notInRoomCount++;
//         logW(
//           "ROOM",
//           "Not in room ($_notInRoomCount/5) connected=$_wasCallReallyConnected",
//         );
//         if (_notInRoomCount >= 5) {
//           logW("ROOM", "Consecutive not-in-room -> handle end");
//           _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//         }
//       } else {
//         _notInRoomCount = 0;
//       }
//     });
//   }
//
//   Future<void> _connectZimUser(UserProfile? user) async {
//     if (user == null || _isZimConnected) return;
//
//     try {
//       logI("ZIM", "connectUser start -> id=${user.memberID}");
//
//       await ZIMKit().connectUser(
//         id: user.memberID.trim(),
//         name: (user.name ?? "User_${user.memberID}").trim(),
//         avatarUrl: user.image ?? "",
//       );
//
//       if (!mounted) return;
//       setState(() => _isZimConnected = true);
//       logI("ZIM", "connectUser SUCCESS -> ${user.memberID}");
//     } catch (e, st) {
//       logE("ZIM", "connectUser FAILED", e, st);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Chat connection failed: ${e.toString().split('\n').first}",
//             ),
//           ),
//         );
//       }
//     }
//   }
//
//   /// âœ… init call invitation service once
//   /// Compatible with: zego_uikit_prebuilt_call ^4.22.2
//   Future<void> _initZegoCallInvitation(UserProfile user) async {
//     final ZegoUIKitSignalingPlugin _signalingPlugin =
//         ZegoUIKitSignalingPlugin();
//
//     if (_zegoInitialized || _zegoInitializing) return;
//
//     try {
//       _zegoInitializing = true;
//       logI("ZEGO_INIT", "init start -> user=${user.memberID}");
//
//       await ZegoUIKitPrebuiltCallInvitationService().init(
//         plugins: [_signalingPlugin],
//         appID: 467997506,
//         appSign:
//             "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",
//         userID: user.memberID.trim(),
//         userName: (user.name ?? "User").trim(),
//         // âœ… DO NOT pass signaling plugin (not needed for your setup + avoids mismatches)
//         // plugins: [ZegoUIKitSignalingPlugin()],  // <-- remove in your versions
//         notificationConfig: ZegoCallInvitationNotificationConfig(
//           androidNotificationConfig: ZegoAndroidNotificationConfig(
//             channelID: "ZegoUIKit",
//             channelName: "Call Notifications",
//             sound: "zego_incoming",
//             icon: "notification_icon",
//           ),
//           iOSNotificationConfig: ZegoIOSNotificationConfig(
//             isSandboxEnvironment: false,
//           ),
//         ),
//         events: ZegoUIKitPrebuiltCallEvents(
//           onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
//             logW(
//               "CALL_END",
//               "reason=${event.reason.name} pending=$_pendingCall connected=$_wasCallReallyConnected",
//             );
//             // If a call was pending/active, handle end safely
//             if (_pendingCall || _wasCallReallyConnected) {
//               _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//             } else {
//               _resetCallTracking();
//             }
//             defaultAction.call();
//           },
//           user: ZegoCallUserEvents(
//             onLeave: (user) {
//               logW("REMOTE_LEAVE", "user=${user.id}");
//               if (_pendingCall || _wasCallReallyConnected) {
//                 _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//               }
//             },
//           ),
//           room: ZegoCallRoomEvents(
//             onStateChanged: (ZegoUIKitRoomState state) {
//               // âœ… No getRoomID() in your version, so only log reason + isRoomLogin
//               logI(
//                 "ROOM_STATE",
//                 "reason=${state.reason} isRoomLogin=${ZegoUIKit().isRoomLogin}",
//               );
//
//               // âœ… We mark "really connected" ONLY when room login succeeds
//               if (state.reason == ZegoRoomStateChangedReason.Logined &&
//                   _pendingCall) {
//                 _pendingCall = false;
//                 _wasCallReallyConnected = true;
//                 _callStartTime = DateTime.now();
//                 _notInRoomCount = 0;
//
//                 logI(
//                   "CONNECTED",
//                   "Room Logined -> start billing timer, maxSec=$_maxAllowedSeconds",
//                 );
//
//                 _startCallLimitTimer(); // start limit only after connected
//               }
//             },
//           ),
//         ),
//         requireConfig: (ZegoCallInvitationData invitationData) {
//           logI(
//             "CONFIG",
//             "type=${invitationData.type} invitees=${invitationData.invitees.length}",
//           );
//           return invitationData.invitees.length > 1
//               ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
//               : invitationData.type == ZegoInvitationType.videoCall
//               ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
//               : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
//         },
//       );
//
//       if (!mounted) return;
//       setState(() => _zegoInitialized = true);
//
//       logI("ZEGO_INIT", "âœ… init SUCCESS");
//     } catch (e, st) {
//       logE("ZEGO_INIT", "âŒ init FAILED", e, st);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Call service init failed: ${e.toString().split('\n').first}",
//             ),
//           ),
//         );
//       }
//     } finally {
//       _zegoInitializing = false;
//     }
//   }
//
//   // âœ… SEND wrapper with logs
//   Future<bool> _sendInviteWithLogs({
//     required String targetUserID,
//     required String targetUserName,
//     required bool isVideoCall,
//     required int pricePerMin,
//   }) async {
//     final userVM = context.read<UserViewModel>();
//     final myId = (userVM.currentUser?.memberID ?? '').trim();
//
//     final inviteeId = targetUserID.trim();
//     final inviteeName = (targetUserName.isEmpty ? "User" : targetUserName)
//         .trim();
//
//     logI(
//       "SEND",
//       "myId=$myId -> inviteeId=$inviteeId name=$inviteeName type=${isVideoCall ? "video" : "voice"} price=$pricePerMin",
//     );
//
//     // âœ… Guard 1: empty
//     if (inviteeId.isEmpty) {
//       logW("SEND", "BLOCKED: inviteeId is empty");
//       return false;
//     }
//
//     // âœ… Guard 2: self call (this is YOUR current error)
//     if (myId.isNotEmpty && inviteeId == myId) {
//       logE("SEND", "BLOCKED: trying to call yourself (inviteeId == myId)");
//       return false;
//     }
//
//     // âœ… Guard 3: service ready
//     if (!_zegoInitialized) {
//       logW("SEND", "BLOCKED: zego not initialized");
//       return false;
//     }
//
//     try {
//       final callID =
//           "${myId}_to_${inviteeId}_${DateTime.now().millisecondsSinceEpoch}";
//       final ok = await ZegoUIKitPrebuiltCallInvitationService().send(
//         invitees: [
//           ZegoCallUser.fromUIKit(
//             ZegoUIKitUser(id: inviteeId, name: inviteeName),
//           ),
//         ],
//         isVideoCall: isVideoCall,
//         callID: callID,
//         customData: '{"price_per_min": $pricePerMin}',
//         timeoutSeconds: 60,
//       );
//
//       logI("SEND", "result ok=$ok callID=$callID");
//       return ok;
//     } catch (e, st) {
//       logE("SEND", "EXCEPTION", e, st);
//       return false;
//     }
//   }
//
//   void _startInviteTimeoutTimer() {
//     _inviteTimeoutTimer?.cancel();
//     _inviteTimeoutTimer = Timer(const Duration(seconds: 70), () {
//       if (_pendingCall && !_wasCallReallyConnected) {
//         logW("INV_TIMEOUT", "No connect within 70s -> reset pending");
//         _resetCallTracking();
//       }
//     });
//   }
//
//   void _startCallLimitTimer() {
//     _callLimitTimer?.cancel();
//     if (_maxAllowedSeconds <= 0) return;
//
//     _callLimitTimer = Timer(Duration(seconds: _maxAllowedSeconds), () {
//       logW("LIMIT", "Max time reached -> leaveRoom + handleCallEnd");
//       ZegoUIKit().leaveRoom();
//       _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Call ended: Time limit reached")),
//         );
//       }
//     });
//   }
//
//   void _handleCallEnd(String staffId, bool isVideoCall) {
//     // if never connected -> no billing
//     if (!_wasCallReallyConnected || _callStartTime == null) {
//       logW("BILL", "End without real connection -> no deduction");
//       _resetCallTracking();
//       return;
//     }
//
//     final now = DateTime.now();
//     final durationSeconds = now.difference(_callStartTime!).inSeconds;
//
//     if (durationSeconds < 15) {
//       logW("BILL", "Call too short ($durationSeconds sec) -> no billing");
//       _resetCallTracking();
//       return;
//     }
//
//     _callLimitTimer?.cancel();
//     _inviteTimeoutTimer?.cancel();
//
//     final minutesFraction = durationSeconds / 60.0;
//     final spent = (minutesFraction * (_currentCallPricePerMin ?? 0)).ceil();
//
//     final userVM = context.read<UserViewModel>();
//     final currentBalance = userVM.currentUser?.coinBalance ?? 0;
//     final newBalance = currentBalance - spent;
//
//     userVM.updateUserCoinBalance(
//       newBalance,
//       staffId,
//       spent,
//       durationSeconds.toString(),
//       isVideoCall ? "video" : "audio",
//     );
//     userVM.updateLocalCoinBalance(newBalance);
//
//     logI(
//       "BILL",
//       "ended -> duration=$durationSeconds sec, spent=$spent, remaining=$newBalance",
//     );
//
//     _resetCallTracking();
//   }
//
//   void _resetCallTracking() {
//     _pendingCall = false;
//     _callStartTime = null;
//     _staffId = null;
//     _currentCallPricePerMin = null;
//     _isCurrentCallVideo = false;
//     _wasCallReallyConnected = false;
//     _maxAllowedSeconds = 0;
//
//     _notInRoomCount = 0;
//     _callLimitTimer?.cancel();
//     _inviteTimeoutTimer?.cancel();
//   }
//
//   @override
//   void dispose() {
//     _callLimitTimer?.cancel();
//     _inviteTimeoutTimer?.cancel();
//     _periodicCheckTimer?.cancel();
//
//     if (_zegoInitialized) {
//       ZegoUIKitPrebuiltCallInvitationService().uninit();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<UserViewModel, StaffViewModel>(
//       builder: (context, userVM, staffVM, child) {
//         final currentUser = userVM.currentUser;
//
//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFF140810),
//                   Color(0xFF3A152A),
//                   Color(0xFF140810),
//                   Color(0xFF140810),
//                 ],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   const SizedBox(height: 10),
//
//                   // Header
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Row(
//                       children: [
//                         SvgPicture.asset(
//                           "assets/Images/bonding.svg",
//                           height: 32,
//                         ),
//                         const Spacer(),
//                         GestureDetector(
//                           onTap: () => bondNavigator.newPage(
//                             context,
//                             page: const WalletScreen(),
//                           ),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               gradient: const LinearGradient(
//                                 colors: [Color(0xFFcc529f), Color(0xFFf86460)],
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Image.asset(
//                                   "assets/Images/goldcoin1.png",
//                                   height: 20,
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   "${currentUser?.coinBalance ?? 0}.00",
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         GestureDetector(
//                           onTap: () => bondNavigator.newPage(
//                             context,
//                             page: const ProfileScreen(backPage: true),
//                           ),
//                           child: CircleAvatar(
//                             radius: 18,
//                             backgroundImage:
//                                 (currentUser?.image != null &&
//                                     currentUser!.image!.isNotEmpty)
//                                 ? NetworkImage(currentUser.image!)
//                                 : const AssetImage("assets/Images/profile.png")
//                                       as ImageProvider,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 12),
//
//                   // status
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Row(
//                       children: [
//                         Icon(
//                           _zegoInitialized ? Icons.check_circle : Icons.info,
//                           color: _zegoInitialized
//                               ? Colors.green
//                               : Colors.white70,
//                           size: 16,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           _zegoInitialized
//                               ? "Call service ready"
//                               : (_zegoInitializing
//                                     ? "Connecting call service..."
//                                     : "Call service not ready"),
//                           style: const TextStyle(
//                             color: Colors.white70,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 10),
//
//                   // Staff List
//                   Expanded(
//                     child: staffVM.isFetchingStaff
//                         ? const Center(
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                             ),
//                           )
//                         : staffVM.staffFetchError != null
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   staffVM.staffFetchError!,
//                                   style: const TextStyle(
//                                     color: Colors.redAccent,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton(
//                                   onPressed: staffVM.fetchStaffDetails,
//                                   child: const Text("Retry"),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : staffVM.staffList.isEmpty
//                         ? const Center(
//                             child: Text(
//                               "No staff available",
//                               style: TextStyle(color: Colors.white70),
//                             ),
//                           )
//                         : RefreshIndicator(
//                             onRefresh: () async {
//                               try {
//                                 final userVM2 = context.read<UserViewModel>();
//                                 await Future.wait([
//                                   staffVM.fetchStaffDetails(),
//                                   userVM2.fetchUserDetails(),
//                                 ]);
//                               } catch (e) {
//                                 if (mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                         "Refresh failed: ${e.toString()}",
//                                       ),
//                                     ),
//                                   );
//                                 }
//                               }
//                             },
//                             child: ListView.builder(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               itemCount: staffVM.staffList.length,
//                               itemBuilder: (context, index) {
//                                 final staff = staffVM.staffList[index];
//                                 return _staffProfileCard(staff);
//                               },
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _staffProfileCard(StaffDataProfile staff) {
//     final age = _calculateAgeFromDOB(staff.dob ?? '');
//     final isOnline = staff.isOnline;
//
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//         child: Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(0.10),
//                 Colors.white.withOpacity(0.04),
//               ],
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AppText(
//                         "${staff.name}, ${age ?? '23'}",
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.circle,
//                             size: 10,
//                             color: isOnline ? Colors.green : Colors.red,
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             isOnline ? "Online" : "Offline",
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   CircleAvatar(
//                     radius: 35,
//                     backgroundImage:
//                         (staff.image != null && staff.image!.isNotEmpty)
//                         ? NetworkImage(staff.image!)
//                         : const AssetImage("assets/Images/videocallprofile.png")
//                               as ImageProvider,
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 10),
//
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: staff.areaOfInterest
//                       .map(
//                         (interest) => Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: _Tag(interest.title),
//                         ),
//                       )
//                       .toList(),
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//
//               AppText(
//                 "No bio available yet...",
//                 color: Colors.white,
//                 fontSize: 15,
//                 maxLines: 3,
//                 fontWeight: FontWeight.w500,
//               ),
//
//               const SizedBox(height: 14),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: _customCallButton(
//                       text: "20/min",
//                       pricePerMin: 20,
//                       isVideoCall: false,
//                       targetUserID: staff.memberID,
//                       targetUserName: staff.name ?? "Staff",
//                       targetStaffId: staff.id,
//                       isTargetOnline: staff.isOnline,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _customCallButton(
//                       text: "60/min",
//                       pricePerMin: 60,
//                       isVideoCall: true,
//                       targetUserID: staff.memberID,
//                       targetUserName: staff.name ?? "Staff",
//                       targetStaffId: staff.id,
//                       isTargetOnline: staff.isOnline,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _customCallButton({
//     required String text,
//     required int pricePerMin,
//     required bool isVideoCall,
//     required String targetUserID,
//     required String targetUserName,
//     required String targetStaffId,
//     required bool isTargetOnline,
//   }) {
//     return Consumer<UserViewModel>(
//       builder: (context, userVM, child) {
//         final balance = userVM.currentUser?.coinBalance ?? 0;
//         if (pricePerMin <= 0) return const SizedBox.shrink();
//
//         return GestureDetector(
//           onTap: () async {
//             if (!_zegoInitialized) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text("Call service not ready yet. Please wait..."),
//                 ),
//               );
//               return;
//             }
//
//             // âœ… prevent sending to offline to avoid failures
//             if (!isTargetOnline) {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text("User is offline")));
//               return;
//             }
//
//             // Balance check
//             if (balance < pricePerMin) {
//               Utils.snackBarErrorMessage("Insufficient balance");
//               return;
//             }
//
//             // Permissions
//             final statuses = await [
//               Permission.microphone,
//               if (isVideoCall) Permission.camera,
//             ].request();
//
//             if (!statuses[Permission.microphone]!.isGranted ||
//                 (isVideoCall && !statuses[Permission.camera]!.isGranted)) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Permissions required")),
//               );
//               return;
//             }
//
//             // Max duration based on balance
//             _maxAllowedSeconds = (balance ~/ pricePerMin) * 60;
//
//             // âœ… send with logs
//             final success = await _sendInviteWithLogs(
//               targetUserID: targetUserID,
//               targetUserName: targetUserName,
//               isVideoCall: isVideoCall,
//               pricePerMin: pricePerMin,
//             );
//
//             if (!success) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Failed to send invitation")),
//               );
//               return;
//             }
//
//             // âœ… mark as pending (DO NOT start billing yet)
//             setState(() {
//               _pendingCall = true;
//               _staffId = targetStaffId;
//               _currentCallPricePerMin = pricePerMin;
//               _isCurrentCallVideo = isVideoCall;
//
//               _wasCallReallyConnected = false;
//               _callStartTime = null;
//               _notInRoomCount = 0;
//             });
//
//             logI(
//               "TRACK",
//               "Pending call started -> target=${targetUserID.trim()} staffID=$targetStaffId price=$pricePerMin maxSec=$_maxAllowedSeconds",
//             );
//
//             _startInviteTimeoutTimer(); // clears if not accepted/connected
//           },
//           child: Container(
//             height: 44,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF9251d0), Color(0xFFf56463)],
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset("assets/Images/goldcoin1.png", height: 20),
//                 const SizedBox(width: 4),
//                 AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
//                 const SizedBox(width: 6),
//                 Icon(
//                   isVideoCall ? Icons.video_call : Icons.call,
//                   color: Colors.white,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   int? _calculateAgeFromDOB(String dob) {
//     if (dob.isEmpty) return null;
//     try {
//       final parts = dob.split('/');
//       if (parts.length != 3) return null;
//       final day = int.tryParse(parts[0]);
//       final month = int.tryParse(parts[1]);
//       final year = int.tryParse(parts[2]);
//       if (day == null || month == null || year == null) return null;
//
//       final birthDate = DateTime(year, month, day);
//       final now = DateTime.now();
//       int age = now.year - birthDate.year;
//       if (now.month < birthDate.month ||
//           (now.month == birthDate.month && now.day < birthDate.day)) {
//         age--;
//       }
//       return age;
//     } catch (_) {
//       return null;
//     }
//   }
// }
//
// class _Tag extends StatelessWidget {
//   final String text;
//   const _Tag(this.text);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         gradient: const LinearGradient(
//           colors: [Color(0xFF45333c), Color(0xFF4a263c)],
//         ),
//         border: Border.all(color: const Color(0xFF5a3c4e)),
//       ),
//       child: AppText(
//         text,
//         color: Colors.white,
//         fontSize: 14,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }
// }
//
// /*
// // lib/BondingScreens/HomeScreen/HomeScreen.dart
//
// import 'dart:async';
// import 'dart:ui';
// import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/Socket.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
// import 'package:bonding_app/BondingScreens/LoginScreens/Model/VerifyOtpModel.dart';
// import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
// import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
// import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
// import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
// import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
// import 'package:zego_uikit/zego_uikit.dart';
// import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
// import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   bool _zegoInitialized = false;
//   bool _isZimConnected = false;
//
//   // â”€â”€â”€ Call Tracking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//   DateTime? _callStartTime;
//   String? _currentCallTargetID;
//   String? _staffId;
//   int? _currentCallPricePerMin;
//   bool _isCurrentCallVideo = false;
//   bool _wasCallReallyConnected =
//       false; // NEW: tracks if call was accepted & connected
//   Timer? _callTimer;
//   Timer? _periodicCheckTimer;
//   int _notInRoomCount = 0;
//   final socketService = SocketService();
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       final userVM = context.read<UserViewModel>();
//       await userVM.fetchUserDetails();
//
//       final user = userVM.currentUser;
//
//       if (user != null && user.memberID.isNotEmpty) {
//         debugPrint(
//           "User fetched â†’ memberID: ${user.memberID}, name: ${user.name}",
//         );
//         await _connectZimUser(user);
//       } else {
//         debugPrint("No valid user after fetchUserDetails()");
//       }
//
//       context.read<StaffViewModel>().fetchStaffDetails();
//       final staff = context.read<StaffViewModel>();
//
//       final staffVM = context.read<StaffViewModel>();
//
//       await staffVM.fetchStaffDetails();
//
//       // ðŸ”¥ connect socket using first staff (example)
//       if (staffVM.staffList.isNotEmpty) {
//         final staffID = staffVM.staffList.first.memberID;
//
//         print("Connecting socket as staff â†’ $staffID");
//
//         socketService.connectStaff(staffID);
//
//         socketService.listenStaffList((data) {
//           staffVM.updateStaffPresence(data);
//         });
//       }
//     });
//
//     // Safety net: periodic check (only for detecting stuck states)
//     _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       if (_callStartTime == null) return;
//
//       if (!ZegoUIKit().isRoomLogin) {
//         _notInRoomCount++;
//         debugPrint("Not in room detected ($_notInRoomCount / 5)");
//         if (_notInRoomCount >= 5 && _wasCallReallyConnected) {
//           debugPrint("Consecutive not-in-room after connected â†’ end call");
//           _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//         }
//       } else {
//         _notInRoomCount = 0;
//       }
//     });
//   }
//
//   Future<void> _connectZimUser(UserProfile? user) async {
//     if (user == null || _isZimConnected) return;
//
//     try {
//       debugPrint("â†’ Starting ZIM connect for ID: ${user.memberID}");
//
//       await ZIMKit().connectUser(
//         id: user.memberID,
//         name: user.name ?? "User_${user.memberID}",
//         avatarUrl: user.image ?? "",
//       );
//       setState(() => _isZimConnected = true);
//       debugPrint("â†’ ZIMKit login SUCCESS for ${user.memberID}");
//     } catch (e, stackTrace) {
//       debugPrint("â†’ ZIMKit login FAILED: $e");
//       debugPrint("Stack trace: $stackTrace");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Chat connection failed: ${e.toString().split('\n').first}",
//             ),
//           ),
//         );
//       }
//     }
//   }
//
//   void _handleCallEnd(String staffId, bool isVideoCall) {
//     if (_callStartTime == null) return;
//
//     final now = DateTime.now();
//     final durationSeconds = now.difference(_callStartTime!).inSeconds;
//
//     // â”€â”€â”€ Guards: skip billing if call was never really connected or too short â”€â”€â”€â”€â”€â”€â”€
//     if (!_wasCallReallyConnected) {
//       debugPrint("Call ended without real connection â†’ no deduction");
//       _resetCallTracking();
//       return;
//     }
//
//     if (durationSeconds < 15) {
//       debugPrint(
//         "Call too short ($durationSeconds s) â†’ likely no meaningful conversation â†’ no billing",
//       );
//       _resetCallTracking();
//       return;
//     }
//
//     // â”€â”€â”€ Real attended call â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//     _callTimer?.cancel();
//
//     // Pro-rated calculation
//     final minutesFraction = durationSeconds / 60.0;
//     final spent = (minutesFraction * (_currentCallPricePerMin ?? 0)).ceil();
//
//     final userVM = context.read<UserViewModel>();
//     final currentBalance = userVM.currentUser?.coinBalance ?? 0;
//     final newBalance = currentBalance - spent;
//
//     // Update backend + local
//     userVM.updateUserCoinBalance(
//       newBalance,
//       staffId,
//       spent,
//       durationSeconds.toString(),
//       isVideoCall ? "video" : "audio",
//     );
//     userVM.updateLocalCoinBalance(newBalance);
//
//     // Show message
//     final message =
//         """
// Call ended!
// Duration: ${durationSeconds}s (${durationSeconds ~/ 60} min ${durationSeconds % 60}s)
// Spent: $spent coins
// Remaining: $newBalance
//     """;
//     // Utils.snackBar(message.trim());
//     print("message?????????? ${message.trim()}");
//
//     _resetCallTracking();
//   }
//
//   void _resetCallTracking() {
//     _callStartTime = null;
//     _currentCallTargetID = null;
//     _staffId = null;
//     _currentCallPricePerMin = null;
//     _isCurrentCallVideo = false;
//     _wasCallReallyConnected = false;
//     _notInRoomCount = 0;
//   }
//
//   @override
//   void dispose() {
//     _callTimer?.cancel();
//     _periodicCheckTimer?.cancel();
//     if (_zegoInitialized) {
//       ZegoUIKitPrebuiltCallInvitationService().uninit();
//     }
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<UserViewModel, StaffViewModel>(
//       builder: (context, userVM, staffVM, child) {
//         final currentUser = userVM.currentUser;
//
//         if (currentUser != null && !_zegoInitialized && !userVM.isLoading) {
//           final userID = currentUser.memberID;
//           final userName = currentUser.name ?? "User";
//
//           ZegoUIKitPrebuiltCallInvitationService().init(
//             appID: 467997506,
//             appSign:
//                 "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",
//             userID: userID,
//             userName: userName,
//             plugins: [ZegoUIKitSignalingPlugin()],
//             notificationConfig: ZegoCallInvitationNotificationConfig(
//               androidNotificationConfig: ZegoAndroidNotificationConfig(
//                 channelID: "ZegoUIKit",
//                 channelName: "Call Notifications",
//                 sound: "zego_incoming",
//                 icon: "notification_icon",
//               ),
//               iOSNotificationConfig: ZegoIOSNotificationConfig(
//                 isSandboxEnvironment: false,
//               ),
//             ),
//             events: ZegoUIKitPrebuiltCallEvents(
//               // Called when call ends (local/remote hang up, timeout, kick out, etc.)
//               onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
//                 debugPrint("Call ended â†’ reason: ${event.reason.name}");
//                 if (_callStartTime != null) {
//                   _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//                   print("sdcs");
//                 }
//                 defaultAction
//                     .call(); // Let ZEGO handle default navigation (pop call page)
//               },
//
//               // Detect remote user leave (alternative way to trigger end)
//               user: ZegoCallUserEvents(
//                 onLeave: (user) {
//                   debugPrint("Remote user left: ${user.id} â†’ ending call");
//                   if (_callStartTime != null) {
//                     _handleCallEnd(_staffId ?? '', _isCurrentCallVideo);
//                   }
//                 },
//               ),
//
//               // Room state change (this replaces your old onCallStateChanged)
//               room: ZegoCallRoomEvents(
//                 onStateChanged: (ZegoUIKitRoomState state) {
//                   debugPrint("Room state changed â†’ reason: ${state.reason}");
//                   if (state.reason == ZegoRoomStateChangedReason.Logined &&
//                       _callStartTime != null) {
//                     // Assuming "connected" â‰ˆ logged in successfully after join
//                     debugPrint("Room connected â†’ real conversation started");
//                     setState(() => _wasCallReallyConnected = true);
//                   }
//                 },
//               ),
//             ),
//             requireConfig: (ZegoCallInvitationData invitationData) {
//               return invitationData.invitees.length > 1
//                   ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
//                   : invitationData.type == ZegoInvitationType.videoCall
//                   ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
//                   : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
//             },
//           );
//
//           _zegoInitialized = true;
//         }
//
//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Color(0xFF140810),
//                   Color(0xFF3A152A),
//                   Color(0xFF140810),
//                   Color(0xFF140810),
//                 ],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   const SizedBox(height: 10),
//
//                   // Header
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Row(
//                       children: [
//                         SvgPicture.asset(
//                           "assets/Images/bonding.svg",
//                           height: 32,
//                         ),
//                         const Spacer(),
//                         GestureDetector(
//                           onTap: () => bondNavigator.newPage(
//                             context,
//                             page: const WalletScreen(),
//                           ),
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               gradient: const LinearGradient(
//                                 colors: [Color(0xFFcc529f), Color(0xFFf86460)],
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Image.asset(
//                                   "assets/Images/goldcoin1.png",
//                                   height: 20,
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   "${currentUser?.coinBalance ?? 0}.00",
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         GestureDetector(
//                           onTap: () => bondNavigator.newPage(
//                             context,
//                             page: const ProfileScreen(backPage: true),
//                           ),
//                           child: CircleAvatar(
//                             radius: 18,
//                             backgroundImage:
//                                 (currentUser?.image != null &&
//                                     currentUser!.image!.isNotEmpty)
//                                 ? NetworkImage(currentUser.image!)
//                                 : const AssetImage("assets/Images/profile.png")
//                                       as ImageProvider,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Search Field
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                         child: Container(
//                           height: 50,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(30),
//                             gradient: const LinearGradient(
//                               colors: [
//                                 Color(0xFF35272d),
//                                 Color(0xFF3e2534),
//                                 Color(0xFF3c1b2f),
//                               ],
//                             ),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.2),
//                               width: 0.8,
//                             ),
//                           ),
//                           child: TextField(
//                             style: const TextStyle(color: Colors.white),
//                             decoration: InputDecoration(
//                               hintText: 'Search by â€œname, call topicsâ€',
//                               hintStyle: const TextStyle(
//                                 color: Color(0xFFc7c7cc),
//                                 fontSize: 16,
//                               ),
//                               prefixIcon: const Icon(
//                                 Icons.search,
//                                 color: Colors.white70,
//                                 size: 22,
//                               ),
//                               border: InputBorder.none,
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 14,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 20),
//
//                   // Staff List
//                   Expanded(
//                     child: staffVM.isFetchingStaff
//                         ? const Center(
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                             ),
//                           )
//                         : staffVM.staffFetchError != null
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   staffVM.staffFetchError!,
//                                   style: const TextStyle(
//                                     color: Colors.redAccent,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 ElevatedButton(
//                                   onPressed: staffVM.fetchStaffDetails,
//                                   child: const Text("Retry"),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : staffVM.staffList.isEmpty
//                         ? const Center(
//                             child: Text(
//                               "No staff available",
//                               style: TextStyle(color: Colors.white70),
//                             ),
//                           )
//                         : RefreshIndicator(
//                             onRefresh: () async {
//                               try {
//                                 final userVM = context.read<UserViewModel>();
//                                 await Future.wait([
//                                   staffVM.fetchStaffDetails(),
//                                   userVM.fetchUserDetails(),
//                                 ]);
//                               } catch (e) {
//                                 if (mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text(
//                                         "Refresh failed: ${e.toString()}",
//                                       ),
//                                     ),
//                                   );
//                                 }
//                               }
//                             },
//
//                             child: Builder(
//                               builder: (BuildContext context) {
//                                 return ListView.builder(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                   ),
//                                   itemCount: staffVM.staffList.length,
//                                   itemBuilder: (context, index) {
//                                     final staff = staffVM.staffList[index];
//                                     return _staffProfileCard(staff);
//                                   },
//                                 );
//                               },
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _staffProfileCard(StaffDataProfile staff) {
//     final age = _calculateAgeFromDOB(staff.dob ?? '');
//     print("/////${staff.dob ?? ""}");
//     final isOnline = staff.isOnline;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//         child: Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.white.withOpacity(0.10),
//                 Colors.white.withOpacity(0.04),
//               ],
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AppText(
//                         "${staff.name}, ${age ?? '23'}",
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.circle,
//                             size: 10,
//                             color: isOnline ? Colors.green : Colors.red,
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             isOnline ? "Online" : "Offline",
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   CircleAvatar(
//                     radius: 35,
//                     backgroundImage:
//                         (staff.image != null && staff.image!.isNotEmpty)
//                         ? NetworkImage(staff.image!)
//                         : const AssetImage("assets/Images/videocallprofile.png")
//                               as ImageProvider,
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 10),
//
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: staff.areaOfInterest
//                       .map(
//                         (interest) => Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: _Tag(interest.title),
//                         ),
//                       )
//                       .toList(),
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//
//               AppText(
//                 "No bio available yet...",
//                 color: Colors.white,
//                 fontSize: 15,
//                 maxLines: 3,
//                 fontWeight: FontWeight.w500,
//               ),
//
//               const SizedBox(height: 14),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: _customCallButton(
//                       text: "20/min",
//                       pricePerMin: 20,
//                       isVideoCall: false,
//                       targetUserID: staff.memberID,
//                       targetUserName: staff.name ?? "Staff",
//                       targetStaffId: staff.id,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _customCallButton(
//                       text: "60/min",
//                       pricePerMin: 60,
//                       isVideoCall: true,
//                       targetUserID: staff.memberID,
//                       targetUserName: staff.name ?? "Staff",
//                       targetStaffId: staff.id,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _customCallButton({
//     required String text,
//     required int pricePerMin,
//     required bool isVideoCall,
//     required String targetUserID,
//     required String targetUserName,
//     required String targetStaffId,
//   }) {
//     return Consumer<UserViewModel>(
//       builder: (context, userVM, child) {
//         final currentUser = userVM.currentUser;
//         final balance = currentUser?.coinBalance ?? 0;
//
//         if (pricePerMin <= 0) return const SizedBox.shrink();
//
//         return GestureDetector(
//           onTap: () async {
//             // Permissions
//             final statuses = await [
//               Permission.microphone,
//               if (isVideoCall) Permission.camera,
//             ].request();
//
//             if (!statuses[Permission.microphone]!.isGranted ||
//                 (isVideoCall && !statuses[Permission.camera]!.isGranted)) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Permissions required")),
//               );
//               return;
//             }
//
//             // Balance check
//             if (balance < pricePerMin) {
//               Utils.snackBarErrorMessage("Insufficient balance");
//               return;
//             }
//
//             // Max duration
//             final maxMinutes = balance ~/ pricePerMin;
//             final maxSeconds = maxMinutes * 60;
//
//             // Send invitation
//             final success = await ZegoUIKitPrebuiltCallInvitationService().send(
//               invitees: [
//                 ZegoCallUser.fromUIKit(
//                   ZegoUIKitUser(id: targetUserID, name: targetUserName),
//                 ),
//               ],
//               isVideoCall: isVideoCall,
//               callID:
//                   "${targetUserID}_${DateTime.now().millisecondsSinceEpoch}",
//               customData: '{"price_per_min": $pricePerMin}',
//               timeoutSeconds: 60,
//             );
//
//             if (!success) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Failed to send invitation")),
//               );
//               return;
//             }
//
//             // Start tracking
//             setState(() {
//               _callStartTime = DateTime.now();
//               _currentCallTargetID = targetUserID;
//               _staffId = targetStaffId;
//               _currentCallPricePerMin = pricePerMin;
//               _isCurrentCallVideo = isVideoCall;
//               _wasCallReallyConnected =
//                   false; // Reset - will be set when connected
//             });
//
//             debugPrint(
//               "Call invitation sent â†’ tracking started | Target: $targetUserID | Staff ID: $targetStaffId | Price: $pricePerMin/min | Max: $maxSeconds sec",
//             );
//
//             // Force end after max time (safety)
//             _callTimer = Timer(Duration(seconds: maxSeconds), () {
//               ZegoUIKit().leaveRoom();
//               _handleCallEnd(targetStaffId, isVideoCall);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Call ended: Time limit reached")),
//               );
//             });
//           },
//           child: Container(
//             height: 44,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF9251d0), Color(0xFFf56463)],
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Image.asset("assets/Images/goldcoin1.png", height: 20),
//                 const SizedBox(width: 4),
//                 AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
//                 const SizedBox(width: 6),
//                 Icon(
//                   isVideoCall ? Icons.video_call : Icons.call,
//                   color: Colors.white,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   int? _calculateAgeFromDOB(String dob) {
//     print("??????$dob");
//     if (dob.isEmpty) return null;
//     try {
//       final parts = dob.split('/');
//       if (parts.length != 3) return null;
//       final day = int.tryParse(parts[0]);
//       final month = int.tryParse(parts[1]);
//       final year = int.tryParse(parts[2]);
//       if (day == null || month == null || year == null) return null;
//
//       final birthDate = DateTime(year, month, day);
//       final now = DateTime.now();
//       int age = now.year - birthDate.year;
//       if (now.month < birthDate.month ||
//           (now.month == birthDate.month && now.day < birthDate.day)) {
//         age--;
//       }
//       return age;
//     } catch (_) {
//       return null;
//     }
//   }
// }
//
// class _Tag extends StatelessWidget {
//   final String text;
//   const _Tag(this.text);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         gradient: const LinearGradient(
//           colors: [Color(0xFF45333c), Color(0xFF4a263c)],
//         ),
//         border: Border.all(color: const Color(0xFF5a3c4e)),
//       ),
//       child: AppText(
//         text,
//         color: Colors.white,
//         fontSize: 14,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }
// }
// */
