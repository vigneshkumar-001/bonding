import 'dart:async';

import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/unblock_user_vm.dart';
import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Repo/call_controller.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/block_user_vm.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart'
    show StaffViewModel;
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String staffMemberId; // BON000... used for calls
  final String staffName;
  final String staffImage;
  final bool isBlocked; // coming from list/api
  final String userId; // mongo userId

  const ChatDetailScreen({
    super.key,
    required this.staffId,
    this.staffMemberId = "",
    required this.isBlocked,
    required this.staffImage,
    required this.staffName,
    required this.userId,
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

  Future<void> _startAudioCall() async {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You blocked this user. Unblock to call.")),
      );
      return;
    }

    final staffMemberId = widget.staffMemberId.trim();
    if (staffMemberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Call not available for this chat yet")),
      );
      return;
    }

    final callController = context.read<CallController>();
    final staffVM = context.read<StaffViewModel>();

    StaffDataProfile? staff;
    if (staffVM.staffList.isEmpty) {
      await staffVM.fetchStaffDetails();
    }

    try {
      staff = staffVM.staffList.firstWhere(
        (s) => s.id == widget.staffId || s.memberID == staffMemberId,
      );
    } catch (_) {}

    final pricePerMin = staff?.audioCallRatePerMinute ?? 0;
    if (pricePerMin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Call rate not available. Try again.")),
      );
      return;
    }

    await callController.startCall(
      context: context,
      enabled: true,
      isTargetOnline: staff?.isOnline ?? true,
      pricePerMin: pricePerMin,
      isVideoCall: false,
      targetUserID: staffMemberId,
      targetUserName: widget.staffName,
      targetStaffMongoId: widget.staffId,
    );
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
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            "Block user?",
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Do you want to block this user? They won't be able to message you.",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: "Reason (optional)",
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                "Cancel",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Yes, Block"),
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
        final cs = Theme.of(ctx).colorScheme;
        final brand = BrandTheme.of(ctx);
        return AlertDialog(
          title: Text(
            "User blocked",
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
          ),
          content: Text(
            "You blocked this user. Do you want to unblock and continue chat?",
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                "Cancel",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                "Unblock",
                style: TextStyle(color: brand.online),
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
        });

        final connected = vm.isSocketConnected && vm.isJoined;
        final showErrorBanner =
            _lastErrorShown != null && _lastErrorShown!.trim().isNotEmpty;
        final showCenterLoader = vm.loading && vm.messages.isEmpty;

        final inputDisabled = _isBlocked == true;

        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);

        return AppScaffold(
          safeArea: true,
          body: Column(
            children: [
              // ---------------- TOP BAR ----------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                        _TopIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => bondNavigator.backPage(context),
                        ),
                        const SizedBox(width: 16),

                        _GradientRingAvatar(
                          imageUrl: widget.staffImage,
                          fallbackText: widget.staffName.isNotEmpty
                              ? widget.staffName.characters.first.toUpperCase()
                              : "S",
                          radius: 22,
                          ringWidth: 2.8,
                          ringColors: brand.primaryGradient.colors,
                        ),

                        // CircleAvatar(
                        //   radius: 24,
                        //   backgroundColor: const Color(0xFF8e51d2).withOpacity(0.3),
                        //   child: const Icon(Icons.person, color: Colors.white, size: 28),
                        // ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.staffName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: cs.onSurface,
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
                                          ? brand.online
                                          : cs.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      connected
                                          ? "Online now"
                                          : "Connecting...",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: connected
                                            ? brand.online
                                            : cs.onSurfaceVariant,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_isBlocked) ...[
                                const SizedBox(height: 3),
                                Text(
                                  "• Blocked",
                                  style: TextStyle(
                                    color: cs.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _TopIconButton(
                          icon: Icons.call,
                          onTap: _startAudioCall,
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          color: cs.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'restrict',
                              child: Text(
                                "Restrict",
                                style: TextStyle(color: cs.onSurface),
                              ),
                            ),
                            PopupMenuItem(
                              value: _isBlocked ? 'unblock' : 'block',
                              child: Text(
                                _isBlocked ? "Unblock" : "Block",
                                style: TextStyle(
                                  color: _isBlocked
                                      ? brand.online
                                      : cs.error,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'report',
                              child: Text(
                                "Report",
                                style: TextStyle(color: cs.error),
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'block') {
                              await _showBlockDialog(context);
                            } else if (value == 'unblock') {
                              await _showBlockedUnblockDialog();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Selected: $value")),
                              );
                            }
                          },
                          child: _TopIconButton(
                            icon: Icons.more_vert,
                          ),
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
                              onRetry: () =>
                                  vm.loadHistory(reset: true, isStaff: false),
                              onClose: () =>
                                  setState(() => _lastErrorShown = null),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ---------------- BODY ----------------
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: showCenterLoader
                          ? const _CenterMiniLoader(
                              key: ValueKey("center_loader"),
                            )
                          : (vm.messages.isEmpty
                                ? Center(
                                    key: const ValueKey("empty"),
                                    child: Text(
                                      "No messages",
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : _MessageList(
                                    key: const ValueKey("list"),
                                    scroll: _scroll,
                                    vm: vm,
                                    showTyping: vm.isStaffTyping,
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
                          color: cs.errorContainer.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          "You blocked this user. Tap to unblock.",
                          style: TextStyle(color: cs.onErrorContainer),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // ---------------- INPUT ----------------
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: inputDisabled
                                ? _showBlockedUnblockDialog
                                : null,
                            child: AbsorbPointer(
                              absorbing: inputDisabled,
                              child: Opacity(
                                opacity: inputDisabled ? 0.55 : 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.7),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _text,
                                    style: TextStyle(
                                      color: cs.onSurface,
                                      fontSize: 16,
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
                                        color: cs.onSurfaceVariant,
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
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: inputDisabled
                              ? _showBlockedUnblockDialog
                              : () => _send(vm),
                          child: Opacity(
                            opacity: inputDisabled ? 0.55 : 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: brand.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: Center(
                                  child: Icon(
                                    Icons.send,
                                    color: cs.onPrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

// ✅ Message list widget
class _MessageList extends StatelessWidget {
  final ScrollController scroll;
  final ChatProviderVm vm;
  final bool showTyping;
  final VoidCallback onAfterBuildMaybeScroll;

  const _MessageList({
    super.key,
    required this.scroll,
    required this.vm,
    required this.showTyping,
    required this.onAfterBuildMaybeScroll,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onAfterBuildMaybeScroll(),
    );

    final typingExtra = showTyping ? 1 : 0;

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: vm.messages.length + 1 + typingExtra,
      itemBuilder: (context, index) {
        if (index == 0) {
          return vm.loadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : const SizedBox(height: 6);
        }

        final typingIndex = vm.messages.length + 1;
        if (showTyping && index == typingIndex) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypingIndicatorBubble(),
            ),
          );
        }

        final m = vm.messages[index - 1];
        final isMine = (m.senderRole ?? "").toLowerCase() == "user";

        return _Bubble(
          text: m.message ?? "",
          isMine: isMine,
          time: m.createdAt,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: cs.onErrorContainer,
              backgroundColor: cs.error.withValues(alpha: 0.12),
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
            child: Icon(Icons.close, color: cs.onErrorContainer, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime time;
  final ChatMsgStatus? status;
  final VoidCallback? onRetry;

  const _Bubble({
    required this.text,
    required this.isMine,
    required this.time,
    this.status,
    this.onRetry,
  });

  String _fmtTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? "PM" : "AM";
    final hh = (h % 12 == 0) ? 12 : (h % 12);
    return "$hh:$m $ap";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brand = BrandTheme.of(context);
    final fg = isMine ? cs.onPrimary : cs.onSurface;

    Widget statusWidget() {
      if (!isMine) return const SizedBox.shrink();
      switch (status) {
        case ChatMsgStatus.sending:
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg.withValues(alpha: 0.9),
              ),
            ),
          );
        case ChatMsgStatus.failed:
          return GestureDetector(
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.error, size: 16, color: cs.error),
            ),
          );
        case ChatMsgStatus.sent:
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.done_all,
              size: 12,
              color: fg.withValues(alpha: 0.9),
            ),
          );
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
          gradient: isMine ? brand.primaryGradient : null,
          color: isMine
              ? null
              : cs.surfaceContainerHighest.withValues(alpha: 0.75),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 18 : 0),
            topRight: Radius.circular(isMine ? 0 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmtTime(time),
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.75),
                      fontSize: 8.5,
                    ),
                  ),
                  statusWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TopIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
          width: 0.6,
        ),
      ),
      child: Icon(icon, color: cs.onSurface, size: 22),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

class _GradientRingAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  final double radius;
  final double ringWidth;
  final List<Color> ringColors;

  const _GradientRingAvatar({
    required this.imageUrl,
    required this.fallbackText,
    required this.radius,
    required this.ringWidth,
    required this.ringColors,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final outer = radius + ringWidth;
    final colors = ringColors.isEmpty
        ? <Color>[cs.primary, cs.secondary, cs.primary]
        : <Color>[...ringColors, ringColors.first];

    Widget innerAvatar({ImageProvider? provider}) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: cs.surfaceContainerHighest,
        backgroundImage: provider,
        child: provider == null
            ? Text(
                fallbackText,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      );
    }

    return SizedBox(
      width: outer * 2,
      height: outer * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: colors),
        ),
        child: Padding(
          padding: EdgeInsets.all(ringWidth),
          child: ClipOval(
            child: imageUrl.trim().isEmpty
                ? innerAvatar()
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    imageBuilder: (context, imageProvider) =>
                        innerAvatar(provider: imageProvider),
                    placeholder: (_, __) => innerAvatar(),
                    errorWidget: (_, __, ___) => innerAvatar(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            double dy(int i) {
              final t = (_c.value * 3 - i).clamp(0.0, 1.0);
              final wave = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return -3.5 * wave;
            }

            Widget dot(int i) => Transform.translate(
                  offset: Offset(0, dy(i)),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                );

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [dot(0), dot(1), dot(2)],
            );
          },
        ),
      ),
    );
  }
}
