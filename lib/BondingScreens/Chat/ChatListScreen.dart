import 'dart:ui';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ZimkitService.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_zim/zego_zim.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class ChatListScreen extends StatefulWidget {
  final bool backPage;
  const ChatListScreen({super.key, required this.backPage});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool isSearchActive = false;

  @override
  void initState() {
    super.initState();
    // Trigger connection if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      userVM.initializeZimConnection(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserViewModel,StaffViewModel>(
      builder: (context, userVM,StaffVM ,child) {

        final isConnected = userVM.isZimConnected;
        final currentUser = userVM.currentUser;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF140810), Color(0xFF3A152A), Color(0xFF140810)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header (same as yours)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => bondNavigator.newPageRemoveUntil(context, page: MainBottomBar()),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF282323),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          ),
                        ),
                        if (!isSearchActive) ...[
                          const SizedBox(width: 15),
                          AppText("Chat", fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ],
                        const Spacer(),
                        if (!isSearchActive)
                          GestureDetector(
                            onTap: () => setState(() => isSearchActive = true),
                            child: Image.asset('assets/Images/search.png', color: Colors.white),
                          ),
                        if (isSearchActive)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF282223), Color(0xFF271c1f), Color(0xFF23121a)],
                                      ),
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
                                    ),
                                    child: TextField(
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Search by name',
                                        hintStyle: const TextStyle(color: Color(0xFFc7c7cc), fontSize: 16),
                                        prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 22),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      ),
                                      onChanged: (value) {
                                        // Optional local filter
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Chat List Area
                  Expanded(
                    child: !isConnected
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text("Connecting to chat...", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                        : ZIMKitConversationListView(
                      // key: ValueKey(isConnected),
                      emptyBuilder: (context, defaultWidget) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            const SizedBox(height: 16),
                            AppText(
                              "No chats yet",
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 8),
                            AppText(
                              "Start a conversation with someone",
                              fontSize: 15,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),

                      lastMessageBuilder: (context, message, defaultWidget) {
                        return DefaultTextStyle(
                          style:  TextStyle(color: Colors.white.withOpacity(0.9),fontSize: 16,fontWeight: FontWeight.w500),
                          child: defaultWidget,
                        );
                      },
                      lastMessageTimeBuilder: (context, time, defaultWidget) {
                        return DefaultTextStyle(
                          style:  TextStyle(color: Colors.white.withOpacity(0.9),fontSize: 16,fontWeight: FontWeight.w500),
                          child: defaultWidget,
                        );
                      },
                      onPressed: (context, conversation, defaultAction) {
                        final staffId = StaffVM.getStaffIdByMemberId(conversation.id) ?? conversation.id;
                        bondNavigator.newPage(
                          context,
                          page: ChatDetailScreen(
                            conversationID: conversation.id,
                            conversationType: ZIMConversationType.peer,
                            name: conversation.name,
                            staffId:staffId,
                          ),
                        );
                      //  69844adad333f7f3aa7b696d
                      },
                      // emptyBuilder: (context) => const Center(
                      //   child: Text(
                      //     "No conversations yet",
                      //     style: TextStyle(color: Colors.white70, fontSize: 18),
                      //   ),
                      // ),
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
}