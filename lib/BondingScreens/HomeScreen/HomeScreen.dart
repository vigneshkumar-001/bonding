// lib/BondingScreens/HomeScreen/HomeScreen.dart

import 'dart:async';
import 'dart:ui';

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
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

import 'package:logger/logger.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/staff_hero_card.dart';

import 'package:bonding_app/config/zego_config.dart';

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

  // ✅ NEW: local ready flag (prevents package crash)
  bool _zegoLocalReady = false;
  String _zegoLocalId = "";

  // ─── Call Tracking ──────────────────────────────────────────────────────
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

        // socketService.connectStaff(staffID);
        socketService.listenStaffList((data) {
          staffVM.updateStaffPresence(data);
        });
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

  // ✅ Your version supports getLocalUser()
  String _getZegoLocalUserIDSafe() {
    try {
      return ZegoUIKit().getLocalUser().id.trim();
    } catch (_) {
      return "";
    }
  }

  Future<bool> _ensureCallPermissions({required bool isVideoCall}) async {
    final permissions = <Permission>[
      Permission.microphone,
      if (isVideoCall) Permission.camera,
    ];

    final statuses = await permissions.request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final camGranted =
        !isVideoCall || (statuses[Permission.camera]?.isGranted ?? false);
    if (micGranted && camGranted) return true;

    final blocked =
        (statuses[Permission.microphone]?.isPermanentlyDenied ?? false) ||
        (statuses[Permission.microphone]?.isRestricted ?? false) ||
        (isVideoCall &&
            ((statuses[Permission.camera]?.isPermanentlyDenied ?? false) ||
                (statuses[Permission.camera]?.isRestricted ?? false)));

    if (!mounted) return false;

    if (blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Microphone/Camera permission is blocked. Please allow it in Settings.",
          ),
          action: SnackBarAction(
            label: "Open Settings",
            onPressed: openAppSettings,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone/Camera permission required")),
      );
    }

    return false;
  }

  Future<void> _waitForZegoLocalReady() async {
    for (int i = 0; i < 30; i++) {
      final id = _getZegoLocalUserIDSafe();
      if (id.isNotEmpty) {
        _zegoLocalId = id;
        if (mounted) setState(() => _zegoLocalReady = true);
        logI("ZEGO_LOCAL", "✅ local user ready -> $_zegoLocalId");
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _zegoLocalId = "";
    if (mounted) setState(() => _zegoLocalReady = false);
    logW(
      "ZEGO_LOCAL",
      "⚠️ local user NOT ready yet. Will block send() until ready.",
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
        appID: zegoAppId,
        appSign: zegoAppSign,
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

      // ✅ CRITICAL: wait for local user id ready (prevents _loginUser null crash)
      await _waitForZegoLocalReady();

      if (!mounted) return;
      setState(() => _zegoInitialized = true);

      logI(
        "ZEGO_INIT",
        "✅ init SUCCESS (localReady=$_zegoLocalReady localId=$_zegoLocalId)",
      );
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

    // ✅ THIS is the important guard to avoid package crash
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
        final brand = BrandTheme.of(context);

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: brand.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Image(
                                  image: AssetImage(
                                    "assets/Images/bonding.png",
                                  ),
                                  height: 30,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: ready
                                        ? Colors.green
                                        : Colors.white54,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ready
                                      ? "Call service ready"
                                      : (_zegoInitializing
                                            ? "Connecting call service..."
                                            : "Call service not ready"),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => bondNavigator.newPage(
                              context,
                              page: const WalletScreen(),
                            ),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: brand.primaryGradient,
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
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => bondNavigator.newPage(
                              context,
                              page: const ProfileScreen(backPage: true),
                            ),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: ClipOval(
                                child:
                                    (currentUser?.image != null &&
                                        currentUser!.image!.isNotEmpty)
                                    ? CachedNetworkImage(
                                        imageUrl: currentUser.image!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => AppLoader(
                                          radius: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            Image.asset(
                                              "assets/Images/profile.png",
                                              fit: BoxFit.cover,
                                            ),
                                      )
                                    : Image.asset(
                                        "assets/Images/profile.png",
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Expanded(
                    child: staffVM.isFetchingStaff
                        ? const AppLoader.center()
                        : staffVM.staffFetchError != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  staffVM.staffFetchError!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
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
                              "No women available",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.white,
                            onRefresh: () async {
                              final userVM2 = context.read<UserViewModel>();
                              await Future.wait([
                                staffVM.fetchStaffDetails(),
                                userVM2.fetchUserDetails(),
                              ]);
                            },
                            child: ListView.builder(
                              physics:
                                  const AlwaysScrollableScrollPhysics(), // ✅ important
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: staffVM.staffList.length,
                              itemBuilder: (context, index) {
                                final staff = staffVM.staffList[index];
                                return _profileCardV2(
                                  context,
                                  staff,
                                  _zegoInitialized && _zegoLocalId.isNotEmpty,
                                );
                              },
                            ),
                          ),
                  ),

                  // Expanded(
                  //   child: staffVM.isFetchingStaff
                  //       ? const Center(
                  //           child: CircularProgressIndicator(
                  //             color: Colors.white,
                  //           ),
                  //         )
                  //       : staffVM.staffFetchError != null
                  //       ? Center(
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Text(
                  //                 staffVM.staffFetchError!,
                  //                 style: const TextStyle(
                  //                   color: Colors.redAccent,
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 16),
                  //               ElevatedButton(
                  //                 onPressed: staffVM.fetchStaffDetails,
                  //                 child: const Text("Retry"),
                  //               ),
                  //             ],
                  //           ),
                  //         )
                  //       : staffVM.staffList.isEmpty
                  //       ? const Center(
                  //           child: Text(
                  //             "No staff available",
                  //             style: TextStyle(color: Colors.white70),
                  //           ),
                  //         )
                  //       : ListView.builder(
                  //           padding: const EdgeInsets.symmetric(horizontal: 16),
                  //           itemCount: staffVM.staffList.length,
                  //           itemBuilder: (context, index) {
                  //             final staff = staffVM.staffList[index];
                  //             return _staffProfileCard(staff, ready);
                  //           },
                  //         ),
                  // ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _staffProfileCard(StaffDataProfile staff, bool ready) {
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
                        staff.name.isNotEmpty ? staff.name : "Women",
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
                      pricePerMin: 20,
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
                      pricePerMin: 60,
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

  Widget _profileCardV2(
    BuildContext context,
    StaffDataProfile staff,
    bool ready,
  ) {
    final title = staff.name.isNotEmpty ? staff.name : "Women";
    final tags = staff.areaOfInterest.map((i) => i.title).toList();

    return StaffHeroCard(
      seed: staff.id.isNotEmpty ? staff.id : staff.memberID,
      title: title,
      subtitle: "Helping you navigate life with clarity and purpose.",
      online: staff.isOnline,
      tags: tags,
      imageUrl: staff.image,
      actions: _staffActionsRowV2(context, staff: staff, ready: ready),
    );
  }

  Widget _staffActionsRowV2(
    BuildContext context, {
    required StaffDataProfile staff,
    required bool ready,
  }) {
    return Row(
      children: [
        Expanded(
          child: _customCallButton(
            enabled: ready,
            text: "${staff.audioCallRatePerMinute}/min",
            pricePerMin: staff.audioCallRatePerMinute,
            isVideoCall: false,
            targetUserID: staff.memberID,
            targetUserName: staff.name.isNotEmpty ? staff.name : "Women",
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
            targetUserName: staff.name.isNotEmpty ? staff.name : "Women",
            targetStaffId: staff.id,
            isTargetOnline: staff.isOnline,
          ),
        ),
        const SizedBox(width: 12),
        _chatSquareButtonV2(context, staff: staff),
      ],
    );
  }

  Widget _chatSquareButtonV2(
    BuildContext context, {
    required StaffDataProfile staff,
  }) {
    return SizedBox(
      height: 44,
      width: 44,
      child: Material(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final currentUser = context.read<UserViewModel>().currentUser;
            if (currentUser == null) return;

            final connected = await ZimConnectionService.ensureConnected(
              context,
              userId: currentUser.memberID,
              userName: currentUser.name ?? "User",
            );
            if (!connected) return;

            final staffId = staff.id;
            final userId = currentUser.id;
            final staffName = staff.name.isNotEmpty ? staff.name : "Women";

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider<ChatProviderVm>(
                  create: (_) => ChatProviderVm(
                    repo: ChatRepository(NetworkApiService()),
                  )..initChat(staffId: staffId, userId: userId, isStaff: false),
                  child: ChatDetailScreen(
                    isBlocked: false,
                    staffImage: staff.image ?? '',
                    staffId: staffId,
                    staffMemberId: staff.memberID,
                    staffName: staffName,
                    userId: userId,
                  ),
                ),
              ),
            );
          },
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _profileCard(
    BuildContext context,
    StaffDataProfile staff,
    bool ready,
  ) {
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
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        staff.name.isNotEmpty ? staff.name : "Women",
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
                      // Row(
                      //   children: const [
                      //     Icon(Icons.circle, size: 8, color: Colors.green),
                      //     SizedBox(width: 6),
                      //     Text(
                      //       "Tamil", // ← can be dynamic from staff model later
                      //       style: TextStyle(
                      //         color: Colors.white70,
                      //         fontSize: 12,
                      //       ),
                      //     ),
                      //   ],
                      // ),
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
                      enabled: ready,
                      text: "${staff.audioCallRatePerMinute}/min",
                      pricePerMin: 20,
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
                      pricePerMin: 60,
                      isVideoCall: true,
                      targetUserID: staff.memberID,
                      targetUserName: staff.name ?? "Women",
                      targetStaffId: staff.id,
                      isTargetOnline: staff.isOnline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final userVM = Provider.of<UserViewModel>(
                        context,
                        listen: false,
                      );
                      final currentUser = userVM.currentUser;
                      if (currentUser == null) return;

                      // (Your Zego check can stay if needed)
                      final connected =
                          await ZimConnectionService.ensureConnected(
                            context,
                            userId: currentUser.memberID,
                            userName: currentUser.name ?? "User",
                          );
                      if (!connected) return;

                      final staffId = staff.id; // staff mongo _id
                      final userId = currentUser.id; // user mongo _id
                      final staffName = staff.name ?? "Women";

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChangeNotifierProvider<ChatProviderVm>(
                                create: (_) =>
                                    ChatProviderVm(
                                      repo: ChatRepository(NetworkApiService()),
                                    )..initChat(
                                      staffId: staffId,
                                      userId: userId,
                                      isStaff: false,
                                    ), // ✅ history + socket init
                                child: ChatDetailScreen(
                                  isBlocked: false,
                                  staffImage: staff.image ?? '',
                                  staffId: staffId,
                                  staffMemberId: staff.memberID,
                                  staffName: staffName,
                                  userId: userId,
                                ),
                              ),
                        ),
                      );
                    },

                    child: Center(
                      child: Image.asset("assets/Images/chaticon.png"),
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
              //     // Inside _profileCard → the Chat button GestureDetector
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
              //                 )..initChat(staffId: staffId, userId: userId,isStaff: false), // ✅ history + socket init
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

  Widget _customCallButton({
    required bool enabled,
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
        final canTap = enabled;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (!canTap) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Call service still connecting, try again."),
                  ),
                );
                return;
              }
              if (!isTargetOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User is offline")),
                );
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

              if (!await _ensureCallPermissions(isVideoCall: isVideoCall)) {
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
              opacity: canTap ? 1.0 : 0.55,
              child: Ink(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1,
                  ),
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
                      color: Colors.white70,
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
