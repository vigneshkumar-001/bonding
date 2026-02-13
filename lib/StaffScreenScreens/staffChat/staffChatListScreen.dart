// lib/StaffScreens/StaffChatListScreen.dart (example)

import 'dart:ui';

import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/staffChatDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:zego_zim/zego_zim.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'package:bonding_app/BondingScreens/Chat/ChatDetailScreen.dart'; // reuse user detail screen

class StaffChatListScreen extends StatefulWidget {
  final bool backPage;
  const StaffChatListScreen({super.key, required this.backPage});

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> {
  @override
  Widget build(BuildContext context) {
    bool isSearchActive = false;
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                   widget.backPage? GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF282323),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      ),
                    ):GestureDetector(
                     onTap: () => bondNavigator.newPageRemoveUntil(context, page: StaffBottomBar(index: 0,)),
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
              Expanded(
                child: ZIMKitConversationListView(
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
                          "Wait for someone message.",
                          fontSize: 15,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                  ),
                  lastMessageBuilder: (context, message, defaultWidget) {
                    return DefaultTextStyle(
                      style: const TextStyle(color: Colors.white70),
                      child: defaultWidget,
                    );
                  },
                  lastMessageTimeBuilder: (context, time, defaultWidget) {
                    return DefaultTextStyle(
                      style: const TextStyle(color: Colors.grey),
                      child: defaultWidget,
                    );
                  },
                  onPressed: (context, conversation, defaultAction) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => staffChatDetailScreen(
                          conversationID: conversation.id,
                          conversationType: ZIMConversationType.peer,
                          name: conversation.name,
                        ),
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
}