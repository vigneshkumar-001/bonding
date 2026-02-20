import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/blocked_users_list_vm.dart';
import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/unblock_user_vm.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockedUsersScreen extends StatefulWidget {
  final bool isStaff;
  final String userId;

  const BlockedUsersScreen({
    super.key,
    required this.isStaff,
    required this.userId,
  });

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  String? _unblockingId; // ✅ row-wise loading id

  @override
  void initState() {
    super.initState();

    AppLogger.log.w(
        "BlockedUsersScreen open staffId/userId: ${widget.userId}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BlockedUsersListVm>().fetchBlockedUsers(
        isStaff: widget.isStaff,
      );
    });
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return "-";
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d/$m/$y";
  }

  Future<void> _onRefresh() async {
    await context.read<BlockedUsersListVm>().fetchBlockedUsers(
      isStaff: widget.isStaff,
    );
  }

  Future<void> _doUnblock({
    required String targetId,
    required String userName,
  }) async {
    if (targetId.isEmpty) return;

    setState(() => _unblockingId = targetId);

    final unblockVm = context.read<UnblockUserVM>();

    final ok = await unblockVm.unblockUser(
      userId: targetId,
      isStaff: widget.isStaff,
    );

    if (!mounted) return;

    setState(() => _unblockingId = null);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$userName unblocked successfully")),
      );

      /// 🔥 Remove locally instead of refetch (no flicker)
      final listVm = context.read<BlockedUsersListVm>();

      listVm.users.removeWhere((u) =>
      (u.userObj?.id ?? u.staffObj?.id) == targetId);

      listVm.notifyListeners();
    } else {
      final err = unblockVm.error ?? "Failed to unblock";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF100a0a),
        child: SafeArea(
          child: Column(
            children: [
              /// 🔹 Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF35272d),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppText(
                      "Blocked users",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: Consumer<BlockedUsersListVm>(
                  builder: (context, vm, _) {
                    /// 🔹 Global loading (only for first load)
                    if (vm.loading  ) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
                      );
                    }

                    /// 🔹 Error
                    if (vm.error != null &&
                        vm.error!.trim().isNotEmpty) {
                      return Center(
                        child: AppText(
                          vm.error!,
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      );
                    }

                    /// 🔹 Empty
                    if (vm.users.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                "No blocked users",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    /// 🔹 List
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0),
                        itemCount: vm.users.length,
                        itemBuilder: (context, index) {
                          final item = vm.users[index];

                          final person =
                              item.userObj ?? item.staffObj;

                          final name =
                          (person?.name ?? "").trim().isNotEmpty
                              ? person!.name
                              : "Unknown";

                          final avatarUrl =
                          (person?.image ?? "").trim();

                          final blockedDate =
                          _fmtDate(item.blockedAt);

                          /// ✅ Correct ID selection
                          final unblockTargetId =
                              item.userObj?.id ??
                                  item.staffObj?.id;

                          /// ✅ Safe row loading logic
                          final isRowLoading =
                              _unblockingId != null &&
                                  unblockTargetId != null &&
                                  _unblockingId ==
                                      unblockTargetId;

                          return Padding(
                            padding:
                            const EdgeInsets.only(bottom: 22.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                  Colors.white.withOpacity(
                                      0.10),
                                  backgroundImage:
                                  avatarUrl.isNotEmpty
                                      ? NetworkImage(
                                      avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? const Icon(Icons.person,
                                      color:
                                      Colors.white70)
                                      : null,
                                ),
                                const SizedBox(width: 16),

                                /// Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        name,
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                      const SizedBox(
                                          height: 4),
                                      AppText(
                                        "Blocked: $blockedDate",
                                        color:
                                        const Color(0XFFc7c7cc),
                                        fontSize: 14,
                                      ),
                                    ],
                                  ),
                                ),

                                /// Unblock Button
                                GestureDetector(
                                  onTap: isRowLoading ||
                                      unblockTargetId ==
                                          null
                                      ? null
                                      : () {
                                    _showUnblockConfirm(
                                      context,
                                      userName: name,
                                      onYes: () async {
                                        Navigator.pop(
                                            context);
                                        await _doUnblock(
                                          targetId:
                                          unblockTargetId,
                                          userName: name,
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xFF29090f),
                                      borderRadius:
                                      BorderRadius
                                          .circular(12),
                                    ),
                                    child: isRowLoading
                                        ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                        Colors.white,
                                      ),
                                    )
                                        : AppText(
                                      "Unblock",
                                      color: const Color(
                                          0xFFf4063a),
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnblockConfirm(
      BuildContext context, {
        required String userName,
        required VoidCallback onYes,
      }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF23171B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text(
          "Unblock user?",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Do you want to unblock $userName?",
          style:
          const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(
                    color: Colors.white70)),
          ),
          TextButton(
            onPressed: onYes,
            child: const Text("Yes",
                style: TextStyle(
                    color: Color(0xFF00ed1c))),
          ),
        ],
      ),
    );
  }
}

/*import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/blocked_users_list_vm.dart';
import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/unblock_user_vm.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockedUsersScreen extends StatefulWidget {
  final bool isStaff;
  final String userId;

  const BlockedUsersScreen({
    super.key,
    required this.isStaff,
    required this.userId,
  });

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  String? _unblockingId; // ✅ row-wise loading (can be blockId or userId)

  @override
  void initState() {
    super.initState();

    AppLogger.log.w("BlockedUsersScreen open staffId/userId: ${widget.userId}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BlockedUsersListVm>().fetchBlockedUsers(
        isStaff: widget.isStaff,
      );
    });
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return "-";
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d/$m/$y";
  }

  Future<void> _onRefresh() async {
    await context.read<BlockedUsersListVm>().fetchBlockedUsers(
      isStaff: widget.isStaff,
    );
  }

  /// ✅ IMPORTANT:
  /// Most backends unblock by blocked record _id (item._id)
  /// If your API expects userId instead, change `targetId` accordingly.
  Future<void> _doUnblock({
    required String targetId,
    required String userName,
  }) async {
    setState(() => _unblockingId = targetId);

    final unblockVm = context.read<UnblockUserVM>();

    final ok = await unblockVm.unblockUser(
      userId: targetId, // ⬅️ keep param name, but send targetId
      isStaff: widget.isStaff,
    );

    if (!mounted) return;

    setState(() => _unblockingId = null);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$userName unblocked successfully")),
      );

      await context.read<BlockedUsersListVm>().fetchBlockedUsers(
        isStaff: widget.isStaff,
      );
    } else {
      final err = unblockVm.error ?? "Failed to unblock";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF100a0a),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF35272d),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppText(
                      "Blocked users",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: Consumer<BlockedUsersListVm>(
                  builder: (context, vm, _) {
                    // loading
                    if (vm.loading ) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    // error
                    if (vm.error != null && vm.error!.trim().isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                vm.error!,
                                color: Colors.redAccent,
                                fontSize: 14,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton(
                                onPressed: () => vm.fetchBlockedUsers(
                                  isStaff: widget.isStaff,
                                ),
                                child: const Text("Retry"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // empty
                    if (vm.users.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                "No blocked users",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // list
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: vm.users.length,
                        itemBuilder: (context, index) {
                          final item = vm.users[index];

                          // ✅ Works for BOTH:
                          // - blocked users list: item.userObj exists
                          // - blocked staff list: item.staffObj exists
                          final person = item.userObj ?? item.staffObj;

                          final name = (person?.name ?? "").trim().isNotEmpty
                              ? (person!.name)
                              : "Unknown";

                          final avatarUrl = (person?.image ?? "").trim();
                          final blockedDate = _fmtDate(item.blockedAt);

                          // ✅ choose what to send for unblock
                          // Most correct: blocked record id (item._id)
                          final unblockTargetId = item.staffObj?.id;

                          final isRowLoading =
                              (_unblockingId == unblockTargetId);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 22.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.10,
                                  ),
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        name,
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      const SizedBox(height: 4),
                                      AppText(
                                        "Blocked: $blockedDate",
                                        color: const Color(0XFFc7c7cc),
                                        fontSize: 14,
                                      ),
                                      const SizedBox(height: 2),
                                      if (item.reason.trim().isNotEmpty)
                                        AppText(
                                          "Reason: ${item.reason}",
                                          color: Colors.white60,
                                          fontSize: 13,
                                        ),
                                    ],
                                  ),
                                ),

                                GestureDetector(
                                  onTap: isRowLoading
                                      ? null
                                      : () {
                                          _showUnblockConfirm(
                                            context,
                                            userName: name,
                                            onYes: () async {
                                              Navigator.pop(context);
                                              await _doUnblock(
                                                targetId: unblockTargetId ?? '',
                                                userName: name,
                                              );
                                            },
                                          );
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF29090f),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: isRowLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : AppText(
                                            "Unblock",
                                            color: const Color(0xFFf4063a),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnblockConfirm(
    BuildContext context, {
    required String userName,
    required VoidCallback onYes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23171B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            "Unblock user?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            "Do you want to unblock $userName?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: onYes,
              child: const Text(
                "Yes",
                style: TextStyle(color: Color(0xFF00ed1c)),
              ),
            ),
          ],
        );
      },
    );
  }
}*/

// import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
// import 'package:flutter/material.dart';
//
// class BlockedUsersScreen extends StatefulWidget {
//   const BlockedUsersScreen({super.key});
//
//   @override
//   State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
// }
//
// class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
//   // Sample blocked users data
//   final List<Map<String, dynamic>> blockedUsers = List.generate(5, (index) => {
//     'name': 'Pooja_25',
//     'blockedDate': '21/07/2025',
//     'image': 'assets/Images/pooja.png', // Replace with actual image path
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         color: const Color(0xFF100a0a),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Top Bar
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         bondNavigator.backPage(context);
//                       },
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF35272d),
//                           borderRadius: BorderRadius.circular(40),
//                         ),
//                         child: const Padding(
//                           padding: EdgeInsets.all(8.0),
//                           child: Icon(
//                             Icons.arrow_back,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     AppText(
//                       "Blocked users",
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.white,
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 20),
//
//               // Blocked Users List
//               Expanded(
//                 child: ListView.builder(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   itemCount: blockedUsers.length,
//                   itemBuilder: (context, index) {
//                     final user = blockedUsers[index];
//
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 30.0),
//                       child: Row(
//                         children: [
//                           // Profile Picture
//                           CircleAvatar(
//                             radius: 28,
//                             backgroundImage: AssetImage(user['image']),
//                           ),
//                           const SizedBox(width: 16),
//
//                           // User Info
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 AppText(
//                                   user['name'],
//
//                                     color: Colors.white,
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w600,
//
//                                 ),
//                                 const SizedBox(height: 4),
//                                 AppText(
//                                   "Blocked: ${user['blockedDate']}",
//
//                                     color: Color(0XFFc7c7cc),
//                                     fontSize: 15,
//
//                                 ),
//                               ],
//                             ),
//                           ),
//
//                           // Unblock Button
//                           GestureDetector(
//                             onTap: () {
//                               // Handle unblock action
//                               setState(() {
//
//                               });
//                               // You can also show a confirmation dialog
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF29090f),
//                                 borderRadius: BorderRadius.circular(12),
//
//                               ),
//                               child:  AppText(
//                                 "Unblock",
//
//                                   color: Color(0xFFf4063a),
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//               // Empty state (optional - show when no blocked users)
//               // if (blockedUsers.isEmpty)
//               //   const Center(
//               //     child: Text(
//               //       "No blocked users",
//               //       style: TextStyle(color: Colors.grey, fontSize: 16),
//               //     ),
//               //   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
