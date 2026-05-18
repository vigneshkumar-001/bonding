import 'dart:ui';

import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
import 'package:bonding_app/BondingScreens/HistoryCard/Model/user_call_history_model.dart';
import 'package:bonding_app/BondingScreens/HistoryCard/ViewModel/user_call_history_vm.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/call_controller.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:provider/provider.dart';

class HistoryCard extends StatefulWidget {
  const HistoryCard({super.key});

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  Future<void> _showAvatarPreview({
    required BuildContext context,
    required String title,
    required String? imageUrl,
  }) async {
    final url = (imageUrl ?? "").trim();
    final heroTag = "history_avatar_${url.isEmpty ? title : url}";

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: Apptheme.backgroundGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                color: Colors.white.withOpacity(0.06),
                                child: InteractiveViewer(
                                  minScale: 0.8,
                                  maxScale: 4,
                                  child: Hero(
                                    tag: heroTag,
                                    child: url.isNotEmpty
                                        ? Image.network(
                                            url,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) {
                                              return Center(
                                                child: Text(
                                                  title.isNotEmpty
                                                      ? title[0].toUpperCase()
                                                      : "?",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 52,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Center(
                                            child: Text(
                                              title.isNotEmpty
                                                  ? title[0].toUpperCase()
                                                  : "?",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 52,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                bondNavigator.newPage(
                                  context,
                                  page: const ProfileScreen(backPage: true),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.white.withOpacity(0.12),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                              ),
                              child: const Text(
                                "View Profile",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // ✅ fetch history once screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyVM = context.read<UserCallHistoryVm>();
      historyVM.fetchUserCallHistory();

      final staffVM = context.read<StaffViewModel>();
      if (staffVM.staffList.isEmpty) {
        staffVM.fetchStaffDetails();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<StaffViewModel, UserViewModel, UserCallHistoryVm>(
      builder: (context, staffVM, userVM, historyVM, child) {
        final currentUser = userVM.currentUser;
        final balance = currentUser?.coinBalance ?? 0;

        // ✅ Filter history by search (staff name / callType / interests)
        final filteredHistory = historyVM.history.where((e) {
          if (_query.trim().isEmpty) return true;
          final q = _query.toLowerCase().trim();
          return (e.staffName.toLowerCase().contains(q)) ||
              (e.callType.name.toLowerCase().contains(q)) ||
              (e.source.name.toLowerCase().contains(q));
        }).toList();

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: Apptheme.backgroundGradient,
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
                        const Image(
                          image: AssetImage("assets/Images/appLogo.png"),
                          height: 32,
                        ),
                        const Spacer(),

                        // Balance
                        GestureDetector(
                          onTap: () {
                            bondNavigator.newPage(
                              context,
                              page: const WalletScreen(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: Apptheme.buttonGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
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
                                  "${balance.toStringAsFixed(0)}.00",
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

                        // Profile
                        GestureDetector(
                          onTap: () => _showAvatarPreview(
                            context: context,
                            title: currentUser?.name ?? "User",
                            imageUrl: currentUser?.image,
                          ),
                          child: Hero(
                            tag:
                                "history_avatar_${(currentUser?.image ?? "").trim().isEmpty ? (currentUser?.name ?? "User") : (currentUser?.image ?? "")}",
                            child: _Avatar(
                              radius: 18,
                              name: currentUser?.name ?? "User",
                              imageUrl: currentUser?.image,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Info banner (same UI style as HomeScreen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history, color: Colors.white70, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Your call history is shown here. Tap Chat to reconnect, or start a new call when available.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 0.8,
                            ),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: "Search by name or type",
                              hintStyle: TextStyle(
                                color: Color(0xFFc7c7cc),
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white70,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
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

                  // ✅ History list (USER SIDE)
                  Expanded(
                    child: historyVM.isLoading
                        ? const Center(
                            child: const AppLoadingIndicator(
                              color: Colors.white,
                            ),
                          )
                        : historyVM.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  historyVM.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: historyVM.fetchUserCallHistory,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : filteredHistory.isEmpty
                        ? const Center(
                            child: Text(
                              "No call history found",
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: historyVM.fetchUserCallHistory,
                            child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: filteredHistory.length,
                              itemBuilder: (context, index) {
                                final item = filteredHistory[index];

                                // ✅ Get staff details from staffVM (for interests / dob / image etc)
                                final staff = staffVM.staffList.firstWhere(
                                  (s) => s.id == item.staffId,
                                  orElse: () => StaffDataProfile(
                                    id: item.staffId,
                                    email: item.staffEmail ?? '',
                                    phone: item.staffPhone,
                                    name: item.staffName,
                                    memberID: item.staffMemberID,
                                    role: 'Staff',
                                    isLogin: true,
                                    isApproved: "1",
                                    areaOfInterest: const [],
                                    isOnline: false,
                                    audioCallAmount: 0,
                                    videoCallAmount: 0,
                                    audioCallRatePerMinute: 0,
                                    videoCallRatePerMinute: 0,
                                    currency: item.currency,
                                    // keep others null/0 (depends on your StaffDataProfile ctor)
                                  ),
                                );

                                return _historyCard(context, staff, item);
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

  Widget _historyCard(
    BuildContext context,
    StaffDataProfile staff,
    UserCallHistoryItem history,
  ) {
    final age = staff.age; // uses your getter
    final typeLabel = history.callType.name.toUpperCase();
    final duration = history.callDurationSeconds;

    // ✅ return null when duration should NOT be shown
    String? durationLabel() {
      // hide duration for message/chat
      if (history.callType == CallType.message ||
          history.callType == CallType.chat) {
        return null;
      }
      if (duration <= 0) return null;

      final mins = duration ~/ 60;
      final secs = duration % 60;

      if (mins == 0) return "${secs}s";
      return "${mins}m ${secs}s";
    }

    final durText = durationLabel();

    // ✅ avoids "TYPE • " when duration is null
    final subtitle = (durText == null || durText.isEmpty)
        ? typeLabel
        : "$typeLabel • $durText";

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
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "${(staff.name).isNotEmpty ? staff.name : history.staffName}${age != null ? ', $age' : ''}",
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: staff.isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            subtitle, // ✅ fixed here
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
                        : (history.staffImage != null &&
                              history.staffImage!.isNotEmpty)
                        ? NetworkImage(history.staffImage!)
                        : const AssetImage("assets/Images/videocallprofile.png")
                              as ImageProvider,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Interests
              if (staff.areaOfInterest.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: staff.areaOfInterest
                        .map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _Tag(i.title),
                          ),
                        )
                        .toList(),
                  ),
                ),

              if (staff.areaOfInterest.isNotEmpty) const SizedBox(height: 10),

              // Amount row
              Row(
                children: [
                  AppText(
                    "Spent: ${history.userSpentAmount} ${history.currency}",
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  const Spacer(),
                  // if (history.userRemainingBalance != null)
                  //   AppText(
                  //     "Bal: ${history.userRemainingBalance} ${history.currency}",
                  //     color: Colors.white70,
                  //     fontSize: 13,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                ],
              ),

              const SizedBox(height: 10),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: _GlassCallButton(
                      enabled: staff.audioCallRatePerMinute > 0,
                      text: "${staff.audioCallRatePerMinute}/min",
                      pricePerMin: staff.audioCallRatePerMinute,
                      isVideoCall: false,
                      targetUserID: staff.memberID, // ZEGO staff id
                      targetUserName:
                          staff.name.isNotEmpty ? staff.name : history.staffName,
                      targetStaffMongoId: staff.id, // Mongo staff _id
                      isTargetOnline: staff.isOnline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GlassCallButton(
                      enabled: staff.videoCallRatePerMinute > 0,
                      text: "${staff.videoCallRatePerMinute}/min",
                      pricePerMin: staff.videoCallRatePerMinute,
                      isVideoCall: true,
                      targetUserID: staff.memberID,
                      targetUserName:
                          staff.name.isNotEmpty ? staff.name : history.staffName,
                      targetStaffMongoId: staff.id,
                      isTargetOnline: staff.isOnline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final userVM = context.read<UserViewModel>();
                      final currentUser = userVM.currentUser;
                      if (currentUser == null) return;

                      final connected = await ZimConnectionService.ensureConnected(
                        context,
                        userId: currentUser.memberID,
                        userName: currentUser.name ?? "User",
                      );
                      if (!connected) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<ChatProviderVm>(
                            create: (_) => ChatProviderVm(
                              repo: ChatRepository(NetworkApiService()),
                            )..initChat(
                                staffId: history.staffId,
                                userId: history.userId,
                                isStaff: false,
                              ),
                            child: ChatDetailScreen(
                              isBlocked: false,
                              staffImage: staff.image ?? history.staffImage ?? '',
                              staffId: history.staffId,
                              staffName: history.staffName,
                              userId: history.userId,
                              staffMemberId: staff.memberID,
                              audioRatePerMin: staff.audioCallRatePerMinute,
                              videoRatePerMin: staff.videoCallRatePerMinute,
                            ),
                          ),
                        ),
                      );
                    },
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
              ),
            ],
          ),
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

class _GlassCallButton extends StatelessWidget {
  final bool enabled;
  final String text;
  final int pricePerMin;
  final bool isVideoCall;
  final String targetUserID;
  final String targetUserName;
  final String targetStaffMongoId;
  final bool isTargetOnline;

  const _GlassCallButton({
    required this.enabled,
    required this.text,
    required this.pricePerMin,
    required this.isVideoCall,
    required this.targetUserID,
    required this.targetUserName,
    required this.targetStaffMongoId,
    required this.isTargetOnline,
  });

  @override
  Widget build(BuildContext context) {
    final callCtrl = context.read<CallController>();

    return GestureDetector(
      onTap: () async {
        await callCtrl.startCall(
          context: context,
          enabled: enabled,
          isTargetOnline: isTargetOnline,
          pricePerMin: pricePerMin,
          isVideoCall: isVideoCall,
          targetUserID: targetUserID,
          targetUserName: targetUserName,
          targetStaffMongoId: targetStaffMongoId,
        );
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
              AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
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
  }
}

class _Avatar extends StatelessWidget {
  final double radius;
  final String name;
  final String? imageUrl;

  const _Avatar({
    required this.radius,
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final first = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "?";
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(imageUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withOpacity(0.10),
      child: Text(
        first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// import 'dart:ui';
//
// import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
// import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart';
// import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
// import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
// import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart'; // ← assuming this exists
// import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
// import 'package:bonding_app/BondingScreens/ProfileScreen/ProfileScreen.dart';
// import 'package:bonding_app/BondingScreens/WalletScreen/WalletScreen.dart';
// import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
// import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
// import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
// import 'package:zego_zim/zego_zim.dart'; // ← ADD THIS LINE
//
// class HistoryCard extends StatefulWidget {
//   const HistoryCard({super.key});
//
//   @override
//   State<HistoryCard> createState() => _HistoryCardState();
// }
//
// class _HistoryCardState extends State<HistoryCard> {
//   @override
//   Widget build(BuildContext context) {
//     return Consumer2<StaffViewModel, UserViewModel>(
//       builder: (context, staffVM, userVM, child) {
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
//
//                         // Coin balance (dynamic if you have user model)
//                         Consumer<UserViewModel>(
//                           builder: (context, userVM, _) {
//                             final balance =
//                                 userVM.currentUser?.coinBalance ?? 10.00;
//                             return GestureDetector(
//                               onTap: () {
//                                 bondNavigator.newPage(
//                                   context,
//                                   page: const WalletScreen(),
//                                 );
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 12,
//                                   vertical: 8,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(8),
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       Color(0xFFcc529f),
//                                       Color(0xFFf86460),
//                                     ],
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     Image.asset(
//                                       "assets/Images/goldcoin1.png",
//                                       height: 20,
//                                     ),
//                                     const SizedBox(width: 6),
//                                     Text(
//                                       "${balance.toStringAsFixed(2)}",
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//
//                         const SizedBox(width: 12),
//
//                         // Profile avatar
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
//                   // Search field
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
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
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
//                               hintText: 'Search by “name, call topics”',
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
//                   // Staff / History List
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
//                               "No history or staff available",
//                               style: TextStyle(color: Colors.white70),
//                             ),
//                           )
//                         : RefreshIndicator(
//                             onRefresh: staffVM.fetchStaffDetails,
//                             child: ListView.builder(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                               ),
//                               itemCount: staffVM.staffList.length,
//                               itemBuilder: (context, index) {
//                                 final staff = staffVM.staffList[index];
//                                 return _profileCard(context, staff);
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
//   Widget _profileCard(BuildContext context, StaffDataProfile staff) {
//     final age = _calculateAge(staff.dob ?? '');
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
//             border: Border.all(
//               color: Colors.white.withOpacity(0.15),
//               width: 0.2,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AppText(
//                         "${staff.name ?? 'Unknown'}, ${age ?? '23'}",
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                       ),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: const [
//                           Icon(Icons.circle, size: 8, color: Colors.green),
//                           SizedBox(width: 6),
//                           Text(
//                             "Tamil", // ← can be dynamic from staff model later
//                             style: TextStyle(
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
//               // Tags / Interests
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: staff.areaOfInterest
//                       .map(
//                         (interest) => Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: _Tag(interest.title ?? ''),
//                         ),
//                       )
//                       .toList(),
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//
//               // Bio / Description
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
//               // Action Buttons
//               Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: _actionButton(
//                       img: "assets/Images/goldcoin1.png",
//                       text: "20/min",
//                       icon: Icons.call,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 2,
//                     child: _actionButton(
//                       img: "assets/Images/goldcoin1.png",
//                       text: "60/min",
//                       icon: Icons.video_call,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//
//                   // Inside _profileCard → the Chat button GestureDetector
//                   Expanded(
//                     child: GestureDetector(
//                       onTap: () async {
//                         final userVM = Provider.of<UserViewModel>(context, listen: false);
//                         final currentUser = userVM.currentUser;
//                         if (currentUser == null) return;
//
//                         // (Your Zego check can stay if needed)
//                         final connected = await ZimConnectionService.ensureConnected(
//                           context,
//                           userId: currentUser.memberID,
//                           userName: currentUser.name ?? "User",
//                         );
//                         if (!connected) return;
//
//                         final staffId = staff.id;          // staff mongo _id
//                         final userId = currentUser.id;     // user mongo _id
//                         final staffName = staff.name ?? "Staff";
//
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => ChangeNotifierProvider<ChatProviderVm>(
//                               create: (_) => ChatProviderVm(
//                                 repo: ChatRepository(NetworkApiService()),
//                               )..initChat(staffId: staffId, userId: userId,isStaff: false), // ✅ history + socket init
//                               child: ChatDetailScreen(
//                                 isBlocked: false,
//                                 staffImage: staff.image ?? '',
//                                 staffId: staffId,
//                                 staffName: staffName,
//                                 userId: userId,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//
//                       // onTap: () async {
//                       //   final userVM = Provider.of<UserViewModel>(
//                       //     context,
//                       //     listen: false,
//                       //   );
//                       //   final currentUser = userVM.currentUser;
//                       //
//                       //   if (currentUser == null) return;
//                       //
//                       //   final connected =
//                       //       await ZimConnectionService.ensureConnected(
//                       //         context,
//                       //         userId: currentUser.memberID,
//                       //         userName: currentUser.name ?? "User",
//                       //       );
//                       //
//                       //   if (!connected) return;
//                       //   bondNavigator.newPage(
//                       //     context,
//                       //     page: ChatDetailScreen(
//                       //       staffId: staff.id,                              // Mongo _id
//                       //       staffName: staff.name ?? "Staff",
//                       //       userId: currentUser.id,                         // Mongo _id
//                       //     ),
//                       //   );
//                       //
//                       //   // bondNavigator.newPage(
//                       //   //   context,
//                       //   //   page: ChatDetailScreen(
//                       //   //     // conversationID: staff.memberID,
//                       //   //     // conversationType: ZIMConversationType.peer,
//                       //   //     // name: staff.name ?? "Staff",
//                       //   //     staffId: staff.id,
//                       //   //     userId: '',
//                       //   //     staffName: '',
//                       //   //   ),
//                       //   // );
//                       // },
//                       child: Center(
//                         child: Image.asset("assets/Images/chaticon.png"),
//                       ),
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
//   Widget _actionButton({
//     required String img,
//     required String text,
//     required IconData icon,
//   }) {
//     return Container(
//       height: 44,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         gradient: const LinearGradient(
//           colors: [Color(0xFF9251d0), Color(0xFFf56463)],
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(img, height: 20),
//           const SizedBox(width: 4),
//           AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
//           const SizedBox(width: 6),
//           Icon(icon, color: Colors.white),
//         ],
//       ),
//     );
//   }
//
//   int? _calculateAge(String dob) {
//     if (dob.isEmpty || dob == 'null') return null;
//
//     // Debug print to see input
//     debugPrint("Calculating age for DOB: '$dob'");
//
//     try {
//       // Expected format: dd/mm/yyyy
//       final parts = dob.split('/');
//       if (parts.length != 3) {
//         debugPrint("Invalid date format: $dob");
//         return null;
//       }
//
//       final day = int.tryParse(parts[0]);
//       final month = int.tryParse(parts[1]);
//       final year = int.tryParse(parts[2]);
//
//       if (day == null || month == null || year == null) {
//         debugPrint("Failed to parse numbers from: $dob");
//         return null;
//       }
//
//       final birthDate = DateTime(year, month, day);
//       final now = DateTime.now();
//
//       int age = now.year - birthDate.year;
//
//       // Adjust if birthday hasn't occurred this year
//       if (now.month < birthDate.month ||
//           (now.month == birthDate.month && now.day < birthDate.day)) {
//         age--;
//       }
//
//       // Age can't be negative or unrealistic
//       if (age < 0 || age > 120) {
//         debugPrint("Calculated age invalid: $age");
//         return null;
//       }
//
//       debugPrint("Calculated age: $age");
//       return age;
//     } catch (e) {
//       debugPrint("Error calculating age: $e");
//       return null;
//     }
//   }
// }
//
// class _Tag extends StatelessWidget {
//   final String text;
//
//   const _Tag(this.text, {super.key});
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
