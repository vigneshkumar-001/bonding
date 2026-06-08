import 'dart:async';
import 'dart:io' show Platform;

import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/unblock_user_vm.dart';
import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Bonding_Utils/Call/ios_call_approval_store.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/block_user_vm.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class ChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String staffImage;
  final String? staffMemberId; // ZEGO user id (BON000...)
  final int? audioRatePerMin;
  final int? videoRatePerMin;
  final bool isBlocked; // coming from list/api
  final String userId; // mongo userId

  const ChatDetailScreen({
    super.key,
    required this.staffId,
    required this.isBlocked,
    required this.staffImage,
    required this.staffName,
    required this.userId,
    this.staffMemberId,
    this.audioRatePerMin,
    this.videoRatePerMin,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _text = TextEditingController();

  Timer? _errorHideTimer;
  String? _lastErrorShown;

  bool _userNearBottom = true;

  // ✅ local block state
  bool _isBlocked = false;

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  bool _callUnlocked(ChatProviderVm vm) {
    return vm.messages.any(
      (m) => (m.senderRole ?? "").toLowerCase() == "staff",
    );
  }

  Future<void> _tryUnlockCallsIfPossible(ChatProviderVm vm) async {
    if (!_callUnlocked(vm)) return;
    await IosCallApprovalStore.markApproved(widget.staffId);
  }

  Future<void> _sendCallInvite({
    required bool isVideo,
    required int pricePerMin,
  }) async {
    if (!_isIOS) return;
    if (_isBlocked) {
      await _showBlockedUnblockDialog();
      return;
    }

    final inviteeId = (widget.staffMemberId ?? "").trim();
    if (inviteeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Call not available for this profile.")),
      );
      return;
    }

    String localId = "";
    try {
      localId = ZegoUIKit().getLocalUser().id.trim();
    } catch (_) {
      localId = "";
    }
    if (localId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Call service still connecting. Try again."),
        ),
      );
      return;
    }
    if (inviteeId == localId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid call target.")));
      return;
    }

    final callID =
        "${localId}_to_${inviteeId}_${DateTime.now().millisecondsSinceEpoch}";

    final ok = await ZegoUIKitPrebuiltCallInvitationService().send(
      invitees: [
        ZegoCallUser.fromUIKit(
          ZegoUIKitUser(id: inviteeId, name: widget.staffName),
        ),
      ],
      isVideoCall: isVideo,
      callID: callID,
      customData: '{"price_per_min": $pricePerMin}',
      timeoutSeconds: 60,
    );

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Call invite failed. Try again.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _isBlocked = widget.isBlocked; // ✅ take initial from screen param
    AppLogger.log.w(
      'ChatDetailScreen staffId=${widget.staffId} userId=${widget.userId} isBlocked=$_isBlocked',
    );
    AppLogger.log.w('ChatDetailScreen staffId=${widget.staffImage} ');

    _scroll.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final max = _scroll.position.maxScrollExtent;
    final current = _scroll.position.pixels;
    _userNearBottom = (max - current) < 220;

    if (_scroll.position.pixels <= 60) {
      final vm = context.read<ChatProviderVm>();
      if (!vm.loadingMore && vm.hasMore) {
        vm.loadHistory(reset: false, isStaff: false);
      }
    }
  }

  @override
  void dispose() {
    _errorHideTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scroll.hasClients) return;

      if (jump) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(ChatProviderVm vm) {
    if (_isBlocked) {
      _showBlockedUnblockDialog();
      return;
    }

    final msg = _text.text.trim();
    if (msg.isEmpty) return;
    final userVM = context.read<UserViewModel>();
    final balance = userVM.currentUser?.coinBalance ?? 0;

    if (balance < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Need minimum 8 coins to send message")),
      );
      return;
    }

    vm.sendMessage(msg);
    _text.clear();

    if (_userNearBottom) _scrollToBottom();
  }

  void _handleErrorIfNeeded(ChatProviderVm vm) {
    final err = (vm.error ?? "").trim();
    if (err.isEmpty) return;
    if (_lastErrorShown == err) return;

    _lastErrorShown = err;

    _errorHideTimer?.cancel();
    _errorHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _lastErrorShown = null);
    });
  }

  // =========================================================
  // ✅ BLOCK DIALOG + API
  // =========================================================
  Future<void> _showBlockDialog(BuildContext context) async {
    final TextEditingController reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF231d1d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            "Block user?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Do you want to block this user? They won't be able to message you.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Reason (optional)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Yes, Block",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _blockUserApi(reasonCtrl.text.trim());
  }

  Future<void> _blockUserApi(String reason) async {
    final blockVm = context.read<BlockUserVM>();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
    );

    final ok = await blockVm.blockUser(
      isStaff: false,
      userId: widget.userId,
      staffId: widget.staffId,
      reason: reason.isEmpty ? "No reason" : reason,
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (ok) {
      setState(() => _isBlocked = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blockVm.lastResponse?.message ?? "User blocked"),
        ),
      );
      Navigator.pop(context, true); // 🔥 RETURN TRUE
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blockVm.error ?? "Block failed")));
    }
  }

  // =========================================================
  // ✅ UNBLOCK DIALOG + API
  // =========================================================
  Future<void> _showBlockedUnblockDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF231d1d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            "User blocked",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            "You blocked this user. Do you want to unblock and continue chat?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Unblock",
                style: TextStyle(color: Color(0xFF00ed1c)),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _unblockUserApi();
    }
  }

  Future<void> _unblockUserApi() async {
    final unblockVm = context.read<UnblockUserVM>();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
    );

    final ok = await unblockVm.unblockUser(
      userId: widget.staffId, // ⚠️ change to blockedId if backend expects it
      isStaff: false,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (ok) {
      setState(() => _isBlocked = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(unblockVm.lastResponse?.message ?? "User unblocked"),
        ),
      );
      Navigator.pop(context, true); // 🔥 RETURN TRUE
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(unblockVm.error ?? "Unblock failed")),
      );
    }
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProviderVm>(
      builder: (context, vm, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleErrorIfNeeded(vm);
          _tryUnlockCallsIfPossible(vm);
        });

        final connected = vm.isSocketConnected && vm.isJoined;
        final showErrorBanner =
            _lastErrorShown != null && _lastErrorShown!.trim().isNotEmpty;
        final showCenterLoader = vm.loading && vm.messages.isEmpty;

        final inputDisabled = _isBlocked == true;
        final callUnlocked = _callUnlocked(vm);
        final inputBottomPadding = _isIOS ? 28.0 : 16.0;
        final messageListPhysics = _isIOS
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics();

        final chatColumn = Column(
          children: [
            // ---------------- TOP BAR ----------------
            _ChatTopBar(
              staffImage: widget.staffImage,
              staffName: widget.staffName,
              connected: connected,
              isBlocked: _isBlocked,
              isIOS: _isIOS,
              callUnlocked: callUnlocked,
              staffMemberId: widget.staffMemberId,
              audioRatePerMin: widget.audioRatePerMin,
              videoRatePerMin: widget.videoRatePerMin,
              onBack: () => bondNavigator.backPage(context),
              onAudioCall: () {
                final rate = widget.audioRatePerMin ?? 0;
                if (rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Audio call not available.")),
                  );
                  return;
                }
                _sendCallInvite(isVideo: false, pricePerMin: rate);
              },
              onVideoCall: () {
                final rate = widget.videoRatePerMin ?? 0;
                if (rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Video call not available.")),
                  );
                  return;
                }
                _sendCallInvite(isVideo: true, pricePerMin: rate);
              },
              onMenuSelected: (value) async {
                if (value == 'block') {
                  await _showBlockDialog(context);
                } else if (value == 'unblock') {
                  await _showBlockedUnblockDialog();
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Selected: $value")));
                }
              },
            ),

            // ✅ Error Banner
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: showErrorBanner
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      child: _ErrorBanner(
                        message: _lastErrorShown!,
                        onRetry: () =>
                            vm.loadHistory(reset: true, isStaff: false),
                        onClose: () => setState(() => _lastErrorShown = null),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ---------------- BODY ----------------
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: showCenterLoader
                    ? const _CenterMiniLoader(key: ValueKey("center_loader"))
                    : (vm.messages.isEmpty
                          ? const Center(
                              key: ValueKey("empty"),
                              child: Text(
                                "No messages",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : _MessageList(
                              key: const ValueKey("list"),
                              scroll: _scroll,
                              vm: vm,
                              physics: messageListPhysics,
                              onAfterBuildMaybeScroll: () {
                                if (_userNearBottom) _scrollToBottom();
                              },
                            )),
              ),
            ),

            // ✅ BLOCKED INFO STRIP (optional nice UI)
            if (inputDisabled)
              GestureDetector(
                onTap: _showBlockedUnblockDialog,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A151B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.25),
                    ),
                  ),
                  child: const Text(
                    "You blocked this user. Tap to unblock.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // ---------------- INPUT ----------------
            Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, inputBottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: inputDisabled ? _showBlockedUnblockDialog : null,
                      child: AbsorbPointer(
                        absorbing: inputDisabled,
                        child: Opacity(
                          opacity: inputDisabled ? 0.55 : 1,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2E36),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                minLines: 1,
                                maxLines: 5,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: inputDisabled
                                      ? "You blocked this user"
                                      : "Message",
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: inputDisabled
                                    ? null
                                    : (_) => _send(vm),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: inputDisabled
                        ? _showBlockedUnblockDialog
                        : () => _send(vm),
                    child: Opacity(
                      opacity: inputDisabled ? 0.55 : 1,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.black87,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        return Scaffold(
          body: _isIOS
              ? _IosChatBody(child: chatColumn)
              : _AndroidChatBody(child: chatColumn),
        );
      },
    );
  }
}

// ✅ Center Small Loader
class _CenterMiniLoader extends StatelessWidget {
  const _CenterMiniLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: const AppLoadingIndicator(radius: 10),
      ),
    );
  }
}

// ✅ Message list widget
class _MessageList extends StatelessWidget {
  final ScrollController scroll;
  final ChatProviderVm vm;
  final VoidCallback onAfterBuildMaybeScroll;
  final ScrollPhysics? physics;

  const _MessageList({
    super.key,
    required this.scroll,
    required this.vm,
    required this.onAfterBuildMaybeScroll,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onAfterBuildMaybeScroll(),
    );

    return ListView.builder(
      controller: scroll,
      physics: physics,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: vm.messages.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return vm.loadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: const AppLoadingIndicator(radius: 10),
                    ),
                  ),
                )
              : const SizedBox(height: 6);
        }

        final m = vm.messages[index - 1];
        final isMine = (m.senderRole ?? "").toLowerCase() == "user";

        return _Bubble(
          text: m.message ?? "",
          isMine: isMine,
          createdAt: m.createdAt,
          status: m.status,
          onRetry: (m.status == ChatMsgStatus.failed)
              ? () => vm.retrySend(m)
              : null,
        );
      },
    );
  }
}

// ✅ Banner widget
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

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
          const SizedBox(width: 8),
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
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Retry"),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime? createdAt;
  final ChatMsgStatus? status;
  final VoidCallback? onRetry;

  const _Bubble({
    required this.text,
    required this.isMine,
    this.createdAt,
    this.status,
    this.onRetry,
  });

  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    final local = dt.toLocal();
    final hour24 = local.hour;
    final hour12 = (hour24 % 12 == 0) ? 12 : (hour24 % 12);
    final minute = local.minute.toString().padLeft(2, "0");
    final ampm = hour24 >= 12 ? "PM" : "AM";
    return "$hour12:$minute $ampm";
  }

  @override
  Widget build(BuildContext context) {
    final incomingBg = const Color(0xFF2D2E36);
    final outgoingGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
    );

    Widget statusWidget() {
      if (!isMine) return const SizedBox.shrink();
      switch (status) {
        case ChatMsgStatus.sending:
          return const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 12,
              height: 12,
              child: const AppLoadingIndicator(radius: 10),
            ),
          );
        case ChatMsgStatus.failed:
          return GestureDetector(
            onTap: onRetry,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.error, size: 16, color: Colors.redAccent),
            ),
          );
        case ChatMsgStatus.sent:
        default:
          return const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.done_all, size: 16, color: Colors.black54),
          );
      }
    }

    final timeText = _formatTime(createdAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: const Radius.circular(22),
            bottomRight: const Radius.circular(22),
          ),
          color: isMine ? null : incomingBg,
          gradient: isMine ? outgoingGradient : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.black87 : Colors.white,
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timeText.isNotEmpty)
                  Text(
                    timeText,
                    style: TextStyle(
                      color: isMine ? Colors.black54 : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                statusWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*// lib/BondingScreens/Chat/ChatDetailScreen.dart
import 'dart:async';
import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/block_user_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String staffName;
  final bool isBlocked;
  final String userId;

  const ChatDetailScreen({
    super.key,
    required this.staffId,
    required this.isBlocked,
    required this.staffName,
    required this.userId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _text = TextEditingController();

  // ✅ Error UI helpers
  Timer? _errorHideTimer;
  String? _lastErrorShown;

  // ✅ only auto-scroll when user is near bottom
  bool _userNearBottom = true;

  @override
  void initState() {
    super.initState();
    AppLogger.log.w('Staff id = ${widget.staffId}');

    _scroll.addListener(_onScroll);

    // scroll to bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(jump: true),
    );
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    // ✅ detect user position near bottom
    final max = _scroll.position.maxScrollExtent;
    final current = _scroll.position.pixels;
    _userNearBottom = (max - current) < 220;

    // ✅ Load more when user scrolls near top
    if (_scroll.position.pixels <= 60) {
      final vm = context.read<ChatProviderVm>();
      if (!vm.loadingMore && vm.hasMore) {
        vm.loadHistory(reset: false, isStaff: false);
      }
    }
  }

  @override
  void dispose() {
    _errorHideTimer?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scroll.hasClients) return;

      if (jump) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(ChatProviderVm vm) {
    final msg = _text.text.trim();
    if (msg.isEmpty) return;

    vm.sendMessage(msg);

    _text.clear();

    // ✅ only scroll if user is already near bottom
    if (_userNearBottom) _scrollToBottom();
  }

  // ✅ When error changes -> print + show banner
  void _handleErrorIfNeeded(ChatProviderVm vm) {
    final err = (vm.error ?? "").trim();
    if (err.isEmpty) return;
    if (_lastErrorShown == err) return;

    _lastErrorShown = err;
    debugPrint("❌ CHAT ERROR: $err");

    _errorHideTimer?.cancel();
    _errorHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _lastErrorShown = null);
    });
  }

  Future<void> _showBlockDialog(BuildContext context) async {
    final TextEditingController reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF231d1d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            "Block user?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Do you want to block this user? They won't be able to message you.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Reason (optional)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Yes, Block",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // ✅ call API
    await _blockUserApi(reasonCtrl.text.trim());
  }

  Future<void> _blockUserApi(String reason) async {
    // BlockUserVM provider
    final blockVm = context.read<BlockUserVM>();

    // show loader
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingIndicator()),
    );

    final ok = await blockVm.blockUser(
      isStaff: false,
      userId: widget.userId,
      staffId: widget.staffId,
      reason: reason.isEmpty ? "No reason" : reason,
    );

    if (!mounted) return;
    Navigator.pop(context); // close loader

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(blockVm.lastResponse?.message ?? "User blocked"),
        ),
      );

      // ✅ back to previous page
      bondNavigator.backPage(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blockVm.error ?? "Block failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProviderVm>(
      builder: (context, vm, _) {
        // ✅ show error when it changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleErrorIfNeeded(vm);
        });

        final connected = vm.isSocketConnected && vm.isJoined;
        final showErrorBanner =
            _lastErrorShown != null && _lastErrorShown!.trim().isNotEmpty;

        // ✅ CENTER LOADER ONLY for first loading (history)
        final showCenterLoader = vm.loading && vm.messages.isEmpty;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: Apptheme.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // ---------------- TOP BAR ----------------
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
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(
                            0xFF8e51d2,
                          ).withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.staffName,
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
                                    decoration: BoxDecoration(
                                      color: connected
                                          ? const Color(0xFF00ed1c)
                                          : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AppText(
                                    connected ? "Connected" : "Connecting...",
                                    color: connected
                                        ? const Color(0xFF00ed1c)
                                        : Colors.orange,
                                    fontSize: 13,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.videocam_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {}, // TODO: Video call
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.white),
                          onPressed: () {}, // TODO: Voice call
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          color: const Color(0xFF35272d),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'restrict',
                              child: Text(
                                "Restrict",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Text(
                                "Block",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Text(
                                "Report",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'block') {
                              await _showBlockDialog(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Selected: $value")),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // ✅ Error Banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: showErrorBanner
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                            child: _ErrorBanner(
                              message: _lastErrorShown!,
                              onRetry: () {
                                vm.loadHistory(reset: true, isStaff: false);
                              },
                              onClose: () {
                                setState(() => _lastErrorShown = null);
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ---------------- BODY ----------------
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: showCenterLoader
                          ? const _CenterMiniLoader(
                              key: ValueKey("center_loader"),
                            )
                          : (vm.messages.isEmpty
                                ? const Center(
                                    key: ValueKey("empty"),
                                    child: Text(
                                      "No messages",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : _MessageList(
                                    key: const ValueKey("list"),
                                    scroll: _scroll,
                                    vm: vm,
                                    onAfterBuildMaybeScroll: () {
                                      // ✅ when new message comes and user is near bottom
                                      if (_userNearBottom) _scrollToBottom();
                                    },
                                  )),
                    ),
                  ),

                  // ---------------- INPUT ----------------
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF231d1d),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: "Message",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _send(vm),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _send(vm),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: Color(0xFFcc529f),
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

// ✅ Center Small Loader
class _CenterMiniLoader extends StatelessWidget {
  const _CenterMiniLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: const AppLoadingIndicator(radius: 10),
      ),
    );
  }
}

// ✅ Message list widget (keeps build clean)
class _MessageList extends StatelessWidget {
  final ScrollController scroll;
  final ChatProviderVm vm;
  final VoidCallback onAfterBuildMaybeScroll;

  const _MessageList({
    super.key,
    required this.scroll,
    required this.vm,
    required this.onAfterBuildMaybeScroll,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onAfterBuildMaybeScroll(),
    );

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: vm.messages.length + 1,
      itemBuilder: (context, index) {
        // ✅ top loader only for pagination
        if (index == 0) {
          return vm.loadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: const AppLoadingIndicator(radius: 10),
                    ),
                  ),
                )
              : const SizedBox(height: 6);
        }

        final m = vm.messages[index - 1];
        final isMine = (m.senderRole ?? "").toLowerCase() == "user";

        return _Bubble(
          text: m.message ?? "",
          isMine: isMine,
          status: m.status,
          onRetry: (m.status == ChatMsgStatus.failed)
              ? () => vm.retrySend(m)
              : null,
        );
      },
    );
  }
}

// ✅ Banner widget
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

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
          const SizedBox(width: 8),
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
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Retry"),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final ChatMsgStatus? status;
  final VoidCallback? onRetry;

  const _Bubble({
    required this.text,
    required this.isMine,
    this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? const Color(0xFF2A1F2E) : const Color(0xFF23171B);

    Widget statusWidget() {
      if (!isMine) return const SizedBox.shrink();
      switch (status) {
        case ChatMsgStatus.sending:
          return const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 12,
              height: 12,
              child: const AppLoadingIndicator(radius: 10),
            ),
          );
        case ChatMsgStatus.failed:
          return GestureDetector(
            onTap: onRetry,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.error, size: 16, color: Colors.redAccent),
            ),
          );
        case ChatMsgStatus.sent:
        default:
          return const SizedBox.shrink();
      }
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMine ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMine ? Radius.zero : const Radius.circular(15),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
            ),
            statusWidget(),
          ],
        ),
      ),
    );
  }
}*/

// // lib/BondingScreens/Chat/ChatDetailScreen.dart
//
// import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
// import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
// import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
// import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:zego_zim/zego_zim.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
//
// class ChatDetailScreen extends StatefulWidget {
//   final String conversationID;
//   final ZIMConversationType conversationType;
//   final String name;
//   final String staffId;
//
//   const ChatDetailScreen({
//     super.key,
//     required this.conversationID,
//     required this.conversationType,
//     required this.name, required this.staffId,
//
//   });
//
//   @override
//   State<ChatDetailScreen> createState() => _ChatDetailScreenState();
// }
//
// class _ChatDetailScreenState extends State<ChatDetailScreen> {
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _textController = TextEditingController();
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _textController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _sendMessage() async {
//     final text = _textController.text.trim();
//     if (text.isEmpty) return;
//
//     final userVM = Provider.of<UserViewModel>(context, listen: false);
//     final balance = userVM.currentUser?.coinBalance ?? 0;
//
//     if (balance < 8) {
//       Utils.snackBarErrorMessage("Insufficient balance! Need 8 coins to send a message.");
//       return;
//     }
//
//     // Deduct 8 coins BEFORE sending
//     final newBalance = balance - 8;
//     userVM.updateLocalCoinBalance(newBalance);
//     userVM.updateUserCoinBalance(
//       newBalance,
//       widget.staffId,           // staffId – you can pass widget.conversationID if needed
//       8,            // coins spent
//       "0",
//       "chat",       // type
//     );
//
//     // Actually send the message via ZIMKit
//     await ZIMKit().sendTextMessage(
//       widget.conversationID,
//       widget.conversationType,
//       text,
//     );
//
//     // Clear input after success
//     _textController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<UserViewModel>(
//       builder: (context, userVM, child) {
//         final balance = userVM.currentUser?.coinBalance ?? 0;
//         print("staffId :::: ${widget.staffId}");
//
//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Color(0xFF120C18), Color(0xFF241024), Color(0xFF120C18)],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // ─── Top Bar ────────────────────────────────────────────────
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//                     child: Row(
//                       children: [
//                         GestureDetector(
//                           onTap: () => bondNavigator.backPage(context),
//                           child: Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.1),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         CircleAvatar(
//                           radius: 24,
//                           backgroundColor: const Color(0xFF8e51d2).withOpacity(0.3),
//                           child: const Icon(Icons.person, color: Colors.white, size: 28),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 widget.name,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Row(
//                                 children: [
//                                   Container(
//                                     width: 10,
//                                     height: 10,
//                                     decoration: const BoxDecoration(
//                                       color: Color(0xFF00ed1c),
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 6),
//                                   AppText(
//                                     "Active now",
//                                     color: Color(0xFF00ed1c),
//                                     fontSize: 13,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.videocam_outlined, color: Colors.white),
//                           onPressed: () {}, // TODO: Video call
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.call, color: Colors.white),
//                           onPressed: () {}, // TODO: Voice call
//                         ),
//                         PopupMenuButton<String>(
//                           icon: const Icon(Icons.more_vert, color: Colors.white),
//                           color: const Color(0xFF35272d),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           itemBuilder: (context) => [
//                             const PopupMenuItem(value: 'restrict', child: Text("Restrict", style: TextStyle(color: Colors.white))),
//                             const PopupMenuItem(value: 'block', child: Text("Block", style: TextStyle(color: Colors.red))),
//                             const PopupMenuItem(value: 'report', child: Text("Report", style: TextStyle(color: Colors.red))),
//                           ],
//                           onSelected: (value) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text("Selected: $value")),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // ─── Messages List ──────────────────────────────────────────
//                   Expanded(
//                     child: ZIMKitMessageListView(
//                       conversationID: widget.conversationID,
//                       conversationType: widget.conversationType,
//                       scrollController: _scrollController,
//                     ),
//                   ),
//
//                   // ─── Custom Input Bar with Coin Check ──────────────────────
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
//                     color: Colors.transparent,
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         // Text input field
//                         Expanded(
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF231d1d),
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                             child: TextField(
//                               controller: _textController,
//                               style: const TextStyle(color: Colors.white, fontSize: 16),
//                               minLines: 1,
//                               maxLines: 5,
//                               textCapitalization: TextCapitalization.sentences,
//                               decoration: InputDecoration(
//                                 hintText: "Message",
//                                 hintStyle: TextStyle(color: Colors.grey[500]),
//                                 border: InputBorder.none,
//                                 contentPadding: EdgeInsets.zero,
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(width: 12),
//
//                         // Send button (with coin check)
//                         GestureDetector(
//                           onTap: _sendMessage,
//                           child: Container(
//                             padding: const EdgeInsets.all(14),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFFcc529f),
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.send,
//                               color: Colors.white,
//                               size: 24,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

class _ChatTopBar extends StatelessWidget {
  final String staffImage;
  final String staffName;
  final bool connected;
  final bool isBlocked;
  final bool isIOS;
  final bool callUnlocked;
  final String? staffMemberId;
  final int? audioRatePerMin;
  final int? videoRatePerMin;
  final VoidCallback onBack;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;
  final Future<void> Function(String value) onMenuSelected;

  const _ChatTopBar({
    required this.staffImage,
    required this.staffName,
    required this.connected,
    required this.isBlocked,
    required this.isIOS,
    required this.callUnlocked,
    required this.staffMemberId,
    required this.audioRatePerMin,
    required this.videoRatePerMin,
    required this.onBack,
    required this.onAudioCall,
    required this.onVideoCall,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = const Color(0xFF2D2E36).withOpacity(0.7);
    const ringGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7B2FF7), Color(0xFFF107A3)],
    );
    final online = connected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: ringGradient,
            ),
            child: CachedNetworkImage(
              imageUrl: staffImage,
              imageBuilder: (context, imageProvider) =>
                  CircleAvatar(radius: 22, backgroundImage: imageProvider),
              placeholder: (context, url) => const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF2D2E36),
                child: AppLoadingIndicator(radius: 10),
              ),
              errorWidget: (context, url, error) => const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF2D2E36),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffName,
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
                      decoration: BoxDecoration(
                        color: online ? const Color(0xFF00ED1C) : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      online ? "Online now" : "Connecting...",
                      color: online
                          ? const Color(0xFF00ED1C)
                          : Colors.orangeAccent,
                      fontSize: 13,
                    ),
                    const SizedBox(width: 10),
                    if (isBlocked)
                      const Text(
                        "• Blocked",
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (isIOS &&
              callUnlocked &&
              (staffMemberId ?? "").trim().isNotEmpty) ...[
            IconButton(
              onPressed: onAudioCall,
              icon: const Icon(Icons.call, color: Colors.white),
            ),
            IconButton(
              onPressed: onVideoCall,
              icon: const Icon(Icons.videocam, color: Colors.white),
            ),
          ],
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white),
            ),
            padding: EdgeInsets.zero,
            color: const Color(0xFF35272d),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'restrict',
                child: Text("Restrict", style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: isBlocked ? 'unblock' : 'block',
                child: Text(
                  isBlocked ? "Unblock" : "Block",
                  style: TextStyle(
                    color: isBlocked ? const Color(0xFF00ed1c) : Colors.red,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text("Report", style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) => onMenuSelected(value),
          ),
        ],
      ),
    );
  }
}

class _IosChatBody extends StatelessWidget {
  final Widget child;

  const _IosChatBody({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: Apptheme.backgroundGradient),
      child: SafeArea(
        // iOS: keep input flush to bottom (we already pad input manually)
        bottom: false,
        child: child,
      ),
    );
  }
}

class _AndroidChatBody extends StatelessWidget {
  final Widget child;

  const _AndroidChatBody({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: Apptheme.backgroundGradient),
      child: SafeArea(
        // Android: respect bottom insets (gesture nav / keyboard)
        bottom: true,
        child: child,
      ),
    );
  }
}
