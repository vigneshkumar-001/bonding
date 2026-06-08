import 'dart:ui';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/Chat/Repository/chat_repository.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/staff_chat_provider_vm.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:provider/provider.dart';

import '../../Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import '../../Reusable_Widgets/BondingNavigator.dart';
import '../StaffBottomNavBar/StaffBottomNavBar.dart';
import 'staffChatDetailScreen.dart';

import 'ViewModel/StaffChatListVm.dart';

class StaffChatListScreen extends StatefulWidget {
  final bool backPage;
  final String staffId;

  const StaffChatListScreen({
    super.key,
    required this.backPage,
    required this.staffId,
  });

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> {
  bool isSearchActive = false;
  String q = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffChatListVm>().connect(
        baseUrl: "https://bnd.twoofus.tech",
        staffId: widget.staffId,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return "";
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? "PM" : "AM";
    final hh = (h % 12 == 0) ? 12 : (h % 12);
    return "$hh:$m $ap";
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StaffChatListVm>();
    final list = vm.chats.where((c) {
      final query = q.trim().toLowerCase();
      if (query.isEmpty) return true;

      final name = (c.user?.name ?? c.userName ?? "User")
          .toString()
          .toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF120C18), Color(0xFF241024), Color(0xFF120C18)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.backPage) {
                          bondNavigator.backPage(context);
                        } else {
                          bondNavigator.newPageRemoveUntil(
                            context,
                            page: StaffBottomBar(index: 0),
                          );
                        }
                      },
                      child: _backBtn(),
                    ),
                    const SizedBox(width: 14),
                    if (!isSearchActive) ...[
                      AppText(
                        "Chats",
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      const Spacer(),
                      _iconBtn(
                        icon: Icons.search,
                        onTap: () => setState(() => isSearchActive = true),
                      ),
                    ] else ...[
                      Expanded(child: _searchBox()),
                      const SizedBox(width: 10),
                      _iconBtn(
                        icon: Icons.close,
                        onTap: () {
                          setState(() {
                            isSearchActive = false;
                            q = "";
                            _searchCtrl.clear();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // ERROR BANNER
              if (vm.errorMessage != null && vm.errorMessage!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _ErrorBanner(
                    message: vm.errorMessage!,
                    onRetry: () => vm.fetchChatList(reset: true),
                  ),
                ),

              Expanded(
                child: Builder(
                  builder: (_) {
                    // FIRST LOAD -> CENTER LOADER
                    if (vm.isLoading && vm.chats.isEmpty) {
                      return const _CenterLoader();
                    }

                    // EMPTY
                    if (!vm.isLoading && list.isEmpty) {
                      return _EmptyState(
                        title: q.isNotEmpty ? "No results" : "No chats yet",
                        subTitle: q.isNotEmpty
                            ? "Try another name."
                            : "Wait for someone to message you.",
                      );
                    }

                    return RefreshIndicator(
                      color: Colors.white,
                      backgroundColor: const Color(0xFF271c1f),
                      onRefresh: () async => vm.fetchChatList(reset: true),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        itemCount: list.length + 1,
                        itemBuilder: (context, i) {
                          // small top loader while refreshing
                          if (i == 0) {
                            return vm.isLoading
                                ? const Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: _TopSmallLoader(),
                                  )
                                : const SizedBox(height: 2);
                          }

                          final c = list[i - 1];

                          return _ChatTile(
                            userName: c.user?.name.toString() ?? '',
                            lastMessage: c.lastMessage,
                            timeText: _fmtTime(c.lastMessageAt),
                            unreadCount: c.unreadCount,
                            userImage: c.user?.image.toString() ?? '',
                            onTap: () async {
                              vm.clearUnread(c.userId);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider(
                                    create: (_) => StaffChatProviderVm(
                                      repo: ChatRepository(NetworkApiService()),
                                    ),
                                    child: StaffChatDetailScreen(
                                      staffImage:
                                          c.user?.image.toString() ?? '',
                                      staffId: widget.staffId,
                                      userId: c.userId,
                                      isBlocked: c.isBlocked,
                                      userName: c.user?.name.toString() ?? '',
                                    ),
                                  ),
                                ),
                              );

                              if (result == true) {
                                vm.fetchChatList(
                                  reset: true,
                                ); // 🔥 REFRESH LIST
                              }

                              // Navigator.push(
                              //      context,
                              //      MaterialPageRoute(
                              //        builder: (_) => ChangeNotifierProvider(
                              //          create: (_) => StaffChatProviderVm(
                              //            repo: ChatRepository(NetworkApiService()),
                              //          ),
                              //          child: StaffChatDetailScreen(
                              //            staffId: widget.staffId,
                              //            userId: c.userId,
                              //            isBlocked: c.isBlocked,
                              //            userName: c.user?.name.toString() ?? '',
                              //          ),
                              //        ),
                              //      ),
                              //    );

                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (_) => StaffChatDetailSocketScreen(
                              //       staffId: widget.staffId,
                              //       userId: c.userId,
                              //       userName: c.user?.name.toString() ?? '',
                              //     ),
                              //   ),
                              // );
                            },
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

  Widget _searchBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF282223), Color(0xFF23121a)],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 0.8,
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: "Search by name",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.8),
              ),
              suffixIcon: q.isEmpty
                  ? null
                  : GestureDetector(
                      onTap: () => setState(() {
                        q = "";
                        _searchCtrl.clear();
                      }),
                      child: Icon(
                        Icons.clear,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.6),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _backBtn() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282323),
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.all(8.0),
      child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
    );
  }
}

// ------------------ WIDGETS ------------------

class _CenterLoader extends StatelessWidget {
  const _CenterLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.14), width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: const AppLoadingIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Loading chats...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSmallLoader extends StatelessWidget {
  const _TopSmallLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.6),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: const AppLoadingIndicator(radius: 10, color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subTitle;

  const _EmptyState({required this.title, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A151B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.redAccent.withOpacity(0.18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String userName;
  final String lastMessage;
  final String timeText;
  final int unreadCount;
  final String? userImage;
  final VoidCallback onTap;

  const _ChatTile({
    required this.userName,
    required this.lastMessage,
    required this.timeText,
    required this.unreadCount,
    required this.onTap,
    this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.6),
        ),
        child: Row(
          children: [
            _Avatar(userName: userName, userImage: userImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isEmpty ? " " : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timeText.isNotEmpty)
                  Text(
                    timeText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$unreadCount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String userName;
  final String? userImage;

  const _Avatar({required this.userName, this.userImage});

  @override
  Widget build(BuildContext context) {
    final first = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white.withOpacity(0.10),
      backgroundImage: (userImage != null && userImage!.trim().isNotEmpty)
          ? NetworkImage(userImage!)
          : null,
      child: (userImage == null || userImage!.trim().isEmpty)
          ? Text(
              first,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

// // lib/StaffScreens/StaffChatListScreen.dart (example)
//
// import 'dart:ui';
//
// import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
// import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
// import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
// import 'package:bonding_app/StaffScreenScreens/staffChat/staffChatDetailScreen.dart';
// import 'package:flutter/material.dart';
// import 'package:zego_zim/zego_zim.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
// import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart'; // reuse user detail screen
//
// class StaffChatListScreen extends StatefulWidget {
//   final bool backPage;
//   const StaffChatListScreen({super.key, required this.backPage});
//
//   @override
//   State<StaffChatListScreen> createState() => _StaffChatListScreenState();
// }
//
// class _StaffChatListScreenState extends State<StaffChatListScreen> {
//   @override
//   Widget build(BuildContext context) {
//     bool isSearchActive = false;
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF120C18), Color(0xFF241024), Color(0xFF120C18)],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     widget.backPage
//                         ? GestureDetector(
//                             onTap: () => bondNavigator.backPage(context),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF282323),
//                                 borderRadius: BorderRadius.circular(40),
//                               ),
//                               padding: const EdgeInsets.all(8.0),
//                               child: const Icon(
//                                 Icons.arrow_back,
//                                 color: Colors.white,
//                                 size: 28,
//                               ),
//                             ),
//                           )
//                         : GestureDetector(
//                             onTap: () => bondNavigator.newPageRemoveUntil(
//                               context,
//                               page: StaffBottomBar(index: 0),
//                             ),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF282323),
//                                 borderRadius: BorderRadius.circular(40),
//                               ),
//                               padding: const EdgeInsets.all(8.0),
//                               child: const Icon(
//                                 Icons.arrow_back,
//                                 color: Colors.white,
//                                 size: 28,
//                               ),
//                             ),
//                           ),
//                     if (!isSearchActive) ...[
//                       const SizedBox(width: 15),
//                       AppText(
//                         "Chat",
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.white,
//                       ),
//                     ],
//                     const Spacer(),
//                     if (!isSearchActive)
//                       GestureDetector(
//                         onTap: () => setState(() => isSearchActive = true),
//                         child: Image.asset(
//                           'assets/Images/search.png',
//                           color: Colors.white,
//                         ),
//                       ),
//                     if (isSearchActive)
//                       Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: BackdropFilter(
//                               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                               child: Container(
//                                 height: 40,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(30),
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       Color(0xFF282223),
//                                       Color(0xFF271c1f),
//                                       Color(0xFF23121a),
//                                     ],
//                                   ),
//                                   border: Border.all(
//                                     color: Colors.white.withOpacity(0.2),
//                                     width: 0.8,
//                                   ),
//                                 ),
//                                 child: TextField(
//                                   style: const TextStyle(color: Colors.white),
//                                   decoration: InputDecoration(
//                                     hintText: 'Search by name',
//                                     hintStyle: const TextStyle(
//                                       color: Color(0xFFc7c7cc),
//                                       fontSize: 16,
//                                     ),
//                                     prefixIcon: const Icon(
//                                       Icons.search,
//                                       color: Colors.white70,
//                                       size: 22,
//                                     ),
//                                     border: InputBorder.none,
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 10,
//                                     ),
//                                   ),
//                                   onChanged: (value) {
//                                     // Optional local filter
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//               Expanded(
//                 child: ZIMKitConversationListView(
//                   emptyBuilder: (context, defaultWidget) => Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.chat_bubble_outline_rounded,
//                           size: 80,
//                           color: Colors.white.withOpacity(0.25),
//                         ),
//                         const SizedBox(height: 16),
//                         AppText(
//                           "No chats yet",
//                           fontSize: 20,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.white70,
//                         ),
//                         const SizedBox(height: 8),
//                         AppText(
//                           "Wait for someone message.",
//                           fontSize: 15,
//                           color: Colors.white54,
//                         ),
//                       ],
//                     ),
//                   ),
//                   lastMessageBuilder: (context, message, defaultWidget) {
//                     return DefaultTextStyle(
//                       style: const TextStyle(color: Colors.white70),
//                       child: defaultWidget,
//                     );
//                   },
//                   lastMessageTimeBuilder: (context, time, defaultWidget) {
//                     return DefaultTextStyle(
//                       style: const TextStyle(color: Colors.grey),
//                       child: defaultWidget,
//                     );
//                   },
//                   onPressed: (context, conversation, defaultAction) {
//                     AppLogger.log.w(conversation.id);
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => staffChatDetailScreen(
//                           conversationID: conversation.id,
//                           conversationType: ZIMConversationType.peer,
//                           name: conversation.name,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
