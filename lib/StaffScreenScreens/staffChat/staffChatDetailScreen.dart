// lib/BondingScreens/Chat/ChatDetailScreen.dart

import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_zim/zego_zim.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class staffChatDetailScreen extends StatefulWidget {
  final String conversationID;
  final ZIMConversationType conversationType;
  final String name;

  const staffChatDetailScreen({
    super.key,
    required this.conversationID,
    required this.conversationType,
    required this.name,

  });

  @override
  State<staffChatDetailScreen> createState() => _staffChatDetailScreenState();
}

class _staffChatDetailScreenState extends State<staffChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // final userVM = Provider.of<UserViewModel>(context, listen: false);
    // final balance = userVM.currentUser?.coinBalance ?? 0;
    //
    // if (balance < 8) {
    //   Utils.snackBarErrorMessage("Insufficient balance! Need 8 coins to send a message.");
    //   return;
    // }
    //
    // // Deduct 8 coins BEFORE sending
    // final newBalance = balance - 8;
    // userVM.updateLocalCoinBalance(newBalance);
    // userVM.updateUserCoinBalance(
    //   newBalance,
    //   "",           // staffId – you can pass widget.conversationID if needed
    //   8,            // coins spent
    //   "0",
    //   "chat",       // type
    // );

    // Actually send the message via ZIMKit
    await ZIMKit().sendTextMessage(
      widget.conversationID,
      widget.conversationType,
      text,
    );

    // Clear input after success
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final balance = userVM.currentUser?.coinBalance ?? 0;

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
                  // ─── Top Bar ────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => bondNavigator.backPage(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF8e51d2).withOpacity(0.3),
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00ed1c),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AppText(
                                    "Active now",
                                    color: Color(0xFF00ed1c),
                                    fontSize: 13,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.videocam_outlined, color: Colors.white),
                          onPressed: () {}, // TODO: Video call
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.white),
                          onPressed: () {}, // TODO: Voice call
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF35272d),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'restrict', child: Text("Restrict", style: TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'block', child: Text("Block", style: TextStyle(color: Colors.red))),
                            const PopupMenuItem(value: 'report', child: Text("Report", style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Selected: $value")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ─── Messages List ──────────────────────────────────────────
                  Expanded(
                    child: ZIMKitMessageListView(
                      conversationID: widget.conversationID,
                      conversationType: widget.conversationType,
                      scrollController: _scrollController,
                    ),
                  ),

                  // ─── Custom Input Bar with Coin Check ──────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    color: Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Text input field
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF231d1d),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: "Message",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Send button (with coin check)
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFcc529f),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
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
