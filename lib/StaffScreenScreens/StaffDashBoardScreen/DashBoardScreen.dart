import 'dart:ui';

import 'package:bonding_app/BondingScreens/Chat/ChatListScreen.dart'; // ← your chat list
import 'package:bonding_app/BondingScreens/HomeScreen/Socket.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/RecentCallScreen/RecentCallScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffProfileScreen/staffProfileScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/WalletFlow/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/StaffWithdrawScreen.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/WithdrawRequestScreen.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/staffChatListScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class BondingDashboardPage extends StatefulWidget {
  const BondingDashboardPage({super.key});

  @override
  State<BondingDashboardPage> createState() => _BondingDashboardPageState();
}

class _BondingDashboardPageState extends State<BondingDashboardPage> {
  bool _zegoInitialized = false;
  bool _isZimConnected = false;
  final socketService = SocketService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final staffVM = context.read<StaffViewModel>();

      // Fetch staff data
      // Existing fetches
      await staffVM.fetchStaffSingleData();
      await staffVM.fetchStaffCallStats();      // from previous
      await staffVM.fetchWeeklyCallGraph();

      final staff = staffVM.currentStaff;


      if (staff != null && staff.memberID.isNotEmpty) {
        debugPrint("Staff fetched → memberID: ${staff.memberID}");
        print("staff:::::::::${staff.memberID??""}");

        socketService.connectStaff(staff.memberID);

        // Connect ZIMKit
        final connected = await ZimConnectionService.ensureConnected(
          context,
          userId: staff.memberID,
          userName: staff.name ?? "Staff_${staff.memberID}",
          avatarUrl: staff.image,
        );

        if (connected) {
          setState(() => _isZimConnected = true);
        }

        _initZego(staff);
      }
    });
  }

  Future<void> _connectZimUser(StaffSingleProfile? staff) async {
    if (staff == null || _isZimConnected) return;

    try {
      await ZIMKit().connectUser(
        id: staff.memberID,
        name: staff.name ?? "Staff_${staff.memberID}",
        avatarUrl: staff.image ?? "",
      );
      setState(() => _isZimConnected = true);
      debugPrint("→ ZIMKit login SUCCESS for staff: ${staff.memberID}");
    } catch (e) {
      debugPrint("→ ZIMKit login FAILED: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chat service failed to connect: $e")),
      );
    }
  }

  void _initZego(StaffSingleProfile staff) {
    if (_zegoInitialized) return;

    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 467997506,
      appSign: "ccc20b79b4824f0b6bff31c38a5cbd512cc98fb41bf4cca25d5c9df21bf0c252",
      userID: staff.memberID,
      userName: staff.name ?? "Staff",
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
      requireConfig: (ZegoCallInvitationData invitationData) {
        return invitationData.invitees.length > 1
            ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
            : invitationData.type == ZegoInvitationType.videoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
      },
    );

    _zegoInitialized = true;
    debugPrint("Zego initialized for staff: ${staff.memberID}");
  }
  Future<void> _refreshAllData() async {
    final staffVM = context.read<StaffViewModel>();

    try {
      await Future.wait([
        staffVM.fetchStaffSingleData(),     // updates earnings, balance, pending, etc.
        // staffVM.fetchStaffCallStats(),      // updates call stats
        // staffVM.fetchWeeklyCallGraph(),     // updates weekly graph
        // Add any other fetches you have (e.g. notifications, messages count, etc.)
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Refresh failed: ${e.toString()}")),
        );
      }
    }}
  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        final staff = vm.currentStaff;

        return Scaffold(
          backgroundColor: const Color(0xFF120810),
          body: RefreshIndicator(
            onRefresh: _refreshAllData,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF5A1F3F), Color(0xFF3A152A), Color(0xFF140810)],
                ),
              ),
              child: SafeArea(
                child: vm.isFetchingSingleStaff
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : vm.singleStaffError != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(vm.singleStaffError!, style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: vm.fetchStaffSingleData,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
                    : staff == null
                    ? const Center(child: Text("No profile data", style: TextStyle(color: Colors.white70)))
                    : SingleChildScrollView(
                      child: Column(
                                      children: [
                      _topBar(staff),
                      const SizedBox(height: 16),
                      earningsCard(staff),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _actionButton('Withdraw'),
                            const SizedBox(width: 12),
                            _actionButton('View transactions →', outlined: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _callsSection(),
                      const SizedBox(height: 16),
                      _quickLinks(),
                      const SizedBox(height: 16),
                      _quickChatAccess(), // ← Chat entry point
            SizedBox(height: 100,)
                                      ],
                                    ),
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(StaffSingleProfile staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SvgPicture.asset("assets/Images/bonding.svg", height: 32),
          const Spacer(),
          // GestureDetector(
          //   onTap: () => bondNavigator.newPage(context, page: const StaffWalletScreen()),
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(8),
          //       gradient: const LinearGradient(colors: [Color(0xFFcc529f), Color(0xFFf86460)]),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Image.asset("assets/Images/goldcoin1.png", height: 20),
          //         const SizedBox(width: 6),
          //         Text(
          //           "${staff.pendingBalance}",
          //           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
bondNavigator.newPage(context, page: StaffProfileScreen(backPage: true,));
            },
            child: CircleAvatar(
              radius: 20,
              backgroundImage: (staff.image != null && staff.image!.isNotEmpty)
                  ? NetworkImage(staff.image!)
                  : const AssetImage("assets/Images/videocallprofile.png") as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget earningsCard(StaffSingleProfile staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                "assets/Images/bg.png",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "Total earnings",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  AppText(
                    "₹${staff.staffEarned!.toStringAsFixed(2)}",
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AppText("Withdrawal Amount: ", color: Colors.white60, fontSize: 16),
                      AppText("₹${staff.pendingBalance!.toStringAsFixed(2)}", color: Color(0xFFFFC107), fontSize: 16),
                    ],
                  ),
                ],
              ),
            ),
            // Positioned(
            //   top: 16,
            //   right: 16,
            //   child: Container(
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //     decoration: BoxDecoration(
            //       color: Colors.black.withOpacity(0.5),
            //       borderRadius: BorderRadius.circular(12),
            //       border: Border.all(color: Colors.white24),
            //     ),
            //     child: Row(
            //       children: const [
            //         Icon(Icons.monetization_on, color: Colors.amber, size: 18),
            //         SizedBox(width: 6),
            //         // Text("1 coin = ₹20", style: TextStyle(color: Colors.white)),
            //       ],
            //     ),
            //   ),
            // ),
            Positioned(
              right: -10,
              bottom: -10,
              child: Image.asset("assets/Images/goldcoin2.png", height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String text, {bool outlined = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (text == 'Withdraw') {
            bondNavigator.newPage(context, page: const WithdrawalRequestScreen());
          } else if (text == 'View transactions →') {
            bondNavigator.newPage(context, page: const WithdrawHistory(backPage: true,)); // ← your history page
            // or any other page: const TransactionHistoryScreen(), etc.
          }
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: outlined
                ? null
                : const LinearGradient(colors: [Color(0xFFB35CF6), Color(0xFFFF6F61)]),
            border: outlined ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
            color: outlined ? Colors.transparent : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: outlined ? Colors.white70 : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _callsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<StaffViewModel>(
        builder: (context, vm, child) {
          if (vm.isFetchingWeeklyGraph || vm.isFetchingCallStats) {
            return const Center(child: CircularProgressIndicator(color: Colors.white70));
          }

          if (vm.weeklyGraphError != null || vm.callStatsError != null) {
            return Column(
              children: [
                Text(vm.weeklyGraphError ?? vm.callStatsError ?? "Error loading stats",
                    style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    vm.fetchWeeklyCallGraph();
                    vm.fetchStaffCallStats();
                  },
                  child: const Text("Retry", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }

          // Map days to calls (Sun → Sat order)
          final dayOrder = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
          final callMap = {for (var d in vm.weeklyCallGraph) d.day: d.calls};

          // Get calls in correct order (fill missing days with 0)
          final orderedCalls = dayOrder.map((day) => callMap[day] ?? 0).toList();

          // Find max calls for scaling bar heights
          final maxCalls = orderedCalls.isEmpty ? 1 : orderedCalls.reduce((a, b) => a > b ? a : b);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText('calls today', color: Colors.white70),
                      SizedBox(height: 4),
                      AppText(
                        vm.callsToday.toString(),
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  Icon(Icons.more_vert, color: Colors.white),
                ],
              ),
              const SizedBox(height: 12),

              // Dynamic Bar Chart
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final calls = orderedCalls[index];
                    final double barHeight = maxCalls == 0 ? 0.0 : (calls / maxCalls.toDouble()) * 80.0;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: barHeight.clamp(4.0, 80.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(colors: [Color(0xFFB35CF6), Color(0xFFFF6F61)]),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),

              // Day Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dayOrder.map((day) => _DayLabel(day)).toList(),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      AppText('Total minutes: ', color: Colors.white60),
                      AppText(
                        '${vm.totalMinutes} min',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: (){
                      bondNavigator.newPage(context, page: RecentCallsPage(backPage: true,));
                    },
                    child: Row(
                      children: [
                        AppText("view history", color: Colors.white60, fontSize: 16),
                        Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF231d1d),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: () => bondNavigator.newPage(context, page: const StaffWalletScreen()),
              leading: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF393434),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.account_balance_wallet, color: Colors.white),
                ),
              ),
              title: const Text('Wallet', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            ),
            const Divider(color: Colors.white24, height: 1),
            ListTile(
              leading: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF393434),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.support_agent, color: Colors.white),
                ),
              ),
              title: const Text('Help & support', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChatAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          bondNavigator.newPage(context, page: const StaffChatListScreen(backPage: true,));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Open Messages",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Reply to users • See new messages",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String day;
  const _DayLabel(this.day);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppText(
        day,
        textAlign: TextAlign.center,
        color: Colors.white,
        fontSize: 14,
      ),
    );
  }
}