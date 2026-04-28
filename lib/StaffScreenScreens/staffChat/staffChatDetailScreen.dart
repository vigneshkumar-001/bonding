// lib/StaffScreenScreens/staffChat/View/StaffChatDetailScreen.dart

import 'dart:async';
import 'package:bonding_app/BondingScreens/BlockedUsers/ViewModel/unblock_user_vm.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/block_user_vm.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/staff_chat_provider_vm.dart';
import 'package:bonding_app/theme/brand_theme.dart';
import 'package:bonding_app/ui/app_loader.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';

class StaffChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String userId;
  final bool isBlocked;
  final String userName;
  final String staffImage;

  const StaffChatDetailScreen({
    super.key,
    required this.staffId,
    required this.isBlocked,
    required this.userId,
    required this.userName,
    required this.staffImage,
  });

  @override
  State<StaffChatDetailScreen> createState() => _StaffChatDetailScreenState();
}

class _StaffChatDetailScreenState extends State<StaffChatDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _text = TextEditingController();

  Timer? _errorHideTimer;
  String? _lastErrorShown;

  bool _userNearBottom = true;

  // ---- For auto scroll + maintain position on pagination
  int _lastMsgCount = 0;
  bool _wasLoadingMore = false;

  bool _maintainPosAfterLoadMore = false;
  double _beforeMaxExtent = 0;
  double _beforePixels = 0;

  // âœ… local block state
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();

    _isBlocked = widget.isBlocked; // âœ… take initial from params

    _scroll.addListener(_onScroll);
    AppLogger.log.w(
      "OPEN STAFF CHAT userId=${widget.userId} blocked=$_isBlocked",
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StaffChatProviderVm>().initChat(
        isStaff: true,
        staffId: widget.staffId,
        userId: widget.userId,
      );
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final max = _scroll.position.maxScrollExtent;
    final current = _scroll.position.pixels;

    _userNearBottom = (max - current) < 220;

    if (_scroll.position.pixels <= 80) {
      final vm = context.read<StaffChatProviderVm>();
      if (!vm.loadingMore && vm.hasMore) {
        _beforeMaxExtent = _scroll.position.maxScrollExtent;
        _beforePixels = _scroll.position.pixels;
        _maintainPosAfterLoadMore = true;

        vm.loadHistory(reset: false, isStaff: true, userId: widget.userId);
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
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;

      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleErrorIfNeeded(StaffChatProviderVm vm) {
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

  void _send(StaffChatProviderVm vm) {
    if (_isBlocked) {
      _showBlockedUnblockDialog();
      return;
    }

    final msg = _text.text.trim();
    if (msg.isEmpty) return;

    vm.sendMessage(msg);
    _text.clear();

    if (_userNearBottom) _scrollToBottom();
  }

  void _maybeMaintainPositionAfterLoadMore(StaffChatProviderVm vm) {
    if (!_maintainPosAfterLoadMore) return;
    if (vm.loadingMore) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;

      final newMax = _scroll.position.maxScrollExtent;
      final delta = newMax - _beforeMaxExtent;

      final target = (_beforePixels + delta).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );

      _scroll.jumpTo(target);
      _maintainPosAfterLoadMore = false;
    });
  }

  void _maybeAutoScrollOnNewMessage(StaffChatProviderVm vm) {
    final newCount = vm.messages.length;

    final loadingMoreNow = vm.loadingMore;
    final justFinishedLoadMore = _wasLoadingMore && !loadingMoreNow;

    if (justFinishedLoadMore) {
      _maybeMaintainPositionAfterLoadMore(vm);
    }

    final isNewMessageArrived = newCount > _lastMsgCount;
    if (isNewMessageArrived && !_wasLoadingMore && _userNearBottom) {
      _scrollToBottom();
    }

    _lastMsgCount = newCount;
    _wasLoadingMore = loadingMoreNow;
  }

  // =========================================================
  // âœ… BLOCK
  // =========================================================
  Future<void> _showBlockDialog(BuildContext context) async {
    final TextEditingController reasonCtrl = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      builder: (_) => const AppLoader.center(),
    );

    final ok = await blockVm.blockUser(
      staffId: widget.staffId,
      isStaff: true,
      userId: widget.userId,
      reason: reason.isEmpty ? "No reason" : reason,
    );

    if (!mounted) return;

    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;
    if (ok) {
      setState(() => _isBlocked = true);

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(blockVm.lastResponse?.message ?? "User blocked"),
        ),
      );

      Navigator.pop(context, true); // ðŸ”¥ RETURN TRUE
    }
    /*   if (ok) {
      setState(() => _isBlocked = true);

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(blockVm.lastResponse?.message ?? "User blocked"),
        ),
      );
    } */
    else {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(blockVm.error ?? "Block failed")));
    }
  }

  // Future<void> _blockUserApi(String reason) async {
  //   final blockVm = context.read<BlockUserVM>();
  //
  //   if (!mounted) return;
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => const Center(child: CircularProgressIndicator()),
  //   );
  //
  //   final ok = await blockVm.blockUser(
  //     staffId: widget.staffId, // âœ… use actual staffId
  //     isStaff: true,
  //     userId: widget.userId,
  //     reason: reason.isEmpty ? "No reason" : reason,
  //   );
  //
  //   if (!mounted) return;
  //   Navigator.pop(context);
  //
  //   if (ok) {
  //     setState(() => _isBlocked = true);
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(blockVm.lastResponse?.message ?? "User blocked"),
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(blockVm.error ?? "Block failed")));
  //   }
  // }

  // =========================================================
  // âœ… UNBLOCK
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
          content: Text(
            "You blocked ${widget.userName}. Do you want to unblock and continue chat?",
            style: const TextStyle(color: Colors.white70),
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

    // show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AppLoader.center(),
    );

    final ok = await unblockVm.unblockUser(
      userId: widget.userId,
      isStaff: true,
    );

    // âœ… screen disposed? stop here
    if (!mounted) return;

    // âœ… close loader safely (only if dialog is open)
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // âœ… still mounted check again (after pop)
    if (!mounted) return;

    if (ok) {
      setState(() => _isBlocked = false);

      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(unblockVm.lastResponse?.message ?? "User unblocked"),
        ),
      );

      Navigator.pop(context, true); // ðŸ”¥ RETURN TRUE
    } else {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(unblockVm.error ?? "Unblock failed")),
      );
    }
  }

  // Future<void> _unblockUserApi() async {
  //   final unblockVm = context.read<UnblockUserVM>();
  //
  //   if (!mounted) return;
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => const Center(child: CircularProgressIndicator()),
  //   );
  //
  //   final ok = await unblockVm.unblockUser(
  //     userId: widget.userId, // âš ï¸ change to blockedId if backend expects it
  //     isStaff: true,
  //   );
  //
  //   if (!mounted) return;
  //   Navigator.pop(context);
  //
  //   if (ok) {
  //     setState(() => _isBlocked = false);
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(unblockVm.lastResponse?.message ?? "User unblocked"),
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(unblockVm.error ?? "Unblock failed")),
  //     );
  //   }
  // }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<StaffChatProviderVm>(
      builder: (context, vm, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleErrorIfNeeded(vm);
          _maybeAutoScrollOnNewMessage(vm);
        });

        final connected = vm.isSocketConnected && vm.isJoined;
        final showErrorBanner =
            _lastErrorShown != null && _lastErrorShown!.trim().isNotEmpty;
        final showCenterLoader = vm.loading && vm.messages.isEmpty;

        final inputDisabled = _isBlocked;

        final cs = Theme.of(context).colorScheme;
        final brand = BrandTheme.of(context);

        return AppScaffold(
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
                        // CircleAvatar(
                        //   radius: 24,
                        //   backgroundColor: const Color(
                        //     0xFF8e51d2,
                        //   ).withOpacity(0.3),
                        //   child: const Icon(
                        //     Icons.person,
                        //     color: Colors.white,
                        //     size: 28,
                        //   ),
                        // ),
                        _GradientRingAvatar(
                          imageUrl: widget.staffImage,
                          fallbackText: widget.userName.isNotEmpty
                              ? widget.userName.characters.first.toUpperCase()
                              : "U",
                          radius: 22,
                          ringWidth: 2.8,
                          ringColors: brand.primaryGradient.colors,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
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
                                    connected ? "Online now" : "Connecting...",
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
                                  const SizedBox(width: 10),
                                  if (_isBlocked)
                                    Text(
                                      "• Blocked",
                                      style: TextStyle(
                                        color: cs.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

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
	                          child: const _TopIconButton(icon: Icons.more_vert),
	                        ),
                      ],
                    ),
                  ),

                  // âœ… Error Banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: showErrorBanner
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                            child: _ErrorBanner(
                              message: _lastErrorShown!,
                              onRetry: () => vm.loadHistory(
                                reset: true,
                                isStaff: true,
                                userId: widget.userId,
                              ),
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
                                    key: ValueKey("empty"),
                                    child: Text(
                                      "No messages",
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scroll,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      8,
                                    ),
                                    itemCount: vm.messages.length + 1,
                                    itemBuilder: (context, index) {
                                       if (index == 0) {
                                         return vm.loadingMore
                                             ? Padding(
                                                 padding: EdgeInsets.symmetric(
                                                   vertical: 8,
                                                 ),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                ),
                                              )
                                             : const SizedBox(height: 6);
                                       }

                                      final m = vm.messages[index - 1];
                                      final isMine =
                                          (m.senderRole ?? "").toLowerCase() ==
                                          "staff";

                                      return _Bubble(
                                        text: m.message ?? "",
                                        isMine: isMine,
                                        time: m.createdAt,
                                        status: m.status,
                                        onRetry:
                                            (m.status == ChatMsgStatus.failed)
                                            ? () => vm.retrySend(m)
                                            : null,
                                      );
                                    },
                                  )),
                    ),
                  ),

                  // âœ… BLOCKED STRIP
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
                          "You blocked ${widget.userName}. Tap to unblock.",
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

// âœ… Center loader
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

// âœ… Bubble
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

// âœ… Error Banner
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
        color: cs.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface,
              backgroundColor: cs.error.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Retry"),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, color: cs.onSurfaceVariant, size: 18),
          ),
        ],
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

/*// lib/StaffScreenScreens/staffChat/View/StaffChatDetailScreen.dart

import 'dart:async';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/block_user_vm.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/staff_chat_provider_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';

class StaffChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String userId;
  final bool isBlocked;
  final String userName;

  const StaffChatDetailScreen({
    super.key,
    required this.staffId,
    required this.isBlocked,
    required this.userId,
    required this.userName,
  });

  @override
  State<StaffChatDetailScreen> createState() => _StaffChatDetailScreenState();
}

class _StaffChatDetailScreenState extends State<StaffChatDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _text = TextEditingController();

  Timer? _errorHideTimer;
  String? _lastErrorShown;

  bool _userNearBottom = true;

  // ---- For auto scroll + maintain position on pagination
  int _lastMsgCount = 0;
  bool _wasLoadingMore = false;

  bool _maintainPosAfterLoadMore = false;
  double _beforeMaxExtent = 0;
  double _beforePixels = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    AppLogger.log.w("OPEN STAFF CHAT userId=${widget.userId}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StaffChatProviderVm>().initChat(
        isStaff: true,
        staffId: widget.staffId,
        userId: widget.userId,
      );
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final max = _scroll.position.maxScrollExtent;
    final current = _scroll.position.pixels;

    // user near bottom?
    _userNearBottom = (max - current) < 220;

    // pagination near top
    if (_scroll.position.pixels <= 80) {
      final vm = context.read<StaffChatProviderVm>();
      if (!vm.loadingMore && vm.hasMore) {
        // capture position BEFORE loading more (to prevent jump)
        _beforeMaxExtent = _scroll.position.maxScrollExtent;
        _beforePixels = _scroll.position.pixels;
        _maintainPosAfterLoadMore = true;

        vm.loadHistory(reset: false, isStaff: true);
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
      if (!mounted || !_scroll.hasClients) return;

      final target = _scroll.position.maxScrollExtent;

      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleErrorIfNeeded(StaffChatProviderVm vm) {
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

  void _send(StaffChatProviderVm vm) {
    final msg = _text.text.trim();
    if (msg.isEmpty) return;

    vm.sendMessage(msg);
    _text.clear();

    // if user is already near bottom -> keep them at bottom
    if (_userNearBottom) _scrollToBottom();
  }

  // âœ… Maintain position after loading older messages
  void _maybeMaintainPositionAfterLoadMore(StaffChatProviderVm vm) {
    if (!_maintainPosAfterLoadMore) return;
    if (vm.loadingMore) return; // wait until loadingMore becomes false

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;

      final newMax = _scroll.position.maxScrollExtent;
      final delta = newMax - _beforeMaxExtent;

      final target = (_beforePixels + delta).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );

      _scroll.jumpTo(target);

      _maintainPosAfterLoadMore = false;
    });
  }

  // âœ… Auto scroll when NEW message arrives (only if user near bottom)
  void _maybeAutoScrollOnNewMessage(StaffChatProviderVm vm) {
    final newCount = vm.messages.length;

    final loadingMoreNow = vm.loadingMore;
    final justFinishedLoadMore = _wasLoadingMore && !loadingMoreNow;

    // maintain pos after pagination finish
    if (justFinishedLoadMore) {
      _maybeMaintainPositionAfterLoadMore(vm);
    }

    // if count increased AND not pagination AND user near bottom -> scroll bottom
    final isNewMessageArrived = newCount > _lastMsgCount;
    if (isNewMessageArrived && !_wasLoadingMore && _userNearBottom) {
      _scrollToBottom();
    }

    _lastMsgCount = newCount;
    _wasLoadingMore = loadingMoreNow;
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

    // âœ… call API
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ok = await blockVm.blockUser(
      staffId: '',
      isStaff: true,
      userId: widget.userId,
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

      // âœ… back to previous page
      bondNavigator.backPage(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blockVm.error ?? "Block failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffChatProviderVm>(
      builder: (context, vm, _) {
        // show error once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleErrorIfNeeded(vm);
          _maybeAutoScrollOnNewMessage(vm);
        });

        final connected = vm.isSocketConnected && vm.isJoined;
        final showErrorBanner =
            _lastErrorShown != null && _lastErrorShown!.trim().isNotEmpty;

        final showCenterLoader = vm.loading && vm.messages.isEmpty;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF140810),
                  Color(0xFF3A152A),
                  Color(0xFF140810),
                ],
              ),
            ),
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
                                widget.userName,
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

                  // âœ… Error Banner
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: showErrorBanner
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                            child: _ErrorBanner(
                              message: _lastErrorShown!,
                              onRetry: () =>
                                  vm.loadHistory(reset: true, isStaff: true),
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
                                ? const Center(
                                    key: ValueKey("empty"),
                                    child: Text(
                                      "No messages",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scroll,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      8,
                                    ),
                                    itemCount: vm.messages.length + 1,
                                    itemBuilder: (context, index) {
                                      // top loader for pagination
                                      if (index == 0) {
                                        return vm.loadingMore
                                            ? const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox(height: 6);
                                      }

                                      final m = vm.messages[index - 1];

                                      // âœ… staff side: mine = staff
                                      final isMine =
                                          (m.senderRole ?? "").toLowerCase() ==
                                          "staff";

                                      return _Bubble(
                                        text: m.message ?? "",
                                        isMine: isMine,
                                        status: m.status,
                                        onRetry:
                                            (m.status == ChatMsgStatus.failed)
                                            ? () => vm.retrySend(m)
                                            : null,
                                      );
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

// âœ… Center loader
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

// âœ… Bubble
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
              child: CircularProgressIndicator(strokeWidth: 2),
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
}

// âœ… Error Banner
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
          const Icon(Icons.error_outline, color: cs.error, size: 18),
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
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
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
// class staffChatDetailScreen extends StatefulWidget {
//   final String conversationID;
//   final ZIMConversationType conversationType;
//   final String name;
//
//   const staffChatDetailScreen({
//     super.key,
//     required this.conversationID,
//     required this.conversationType,
//     required this.name,
//
//   });
//
//   @override
//   State<staffChatDetailScreen> createState() => _staffChatDetailScreenState();
// }
//
// class _staffChatDetailScreenState extends State<staffChatDetailScreen> {
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
//     // final userVM = Provider.of<UserViewModel>(context, listen: false);
//     // final balance = userVM.currentUser?.coinBalance ?? 0;
//     //
//     // if (balance < 8) {
//     //   Utils.snackBarErrorMessage("Insufficient balance! Need 8 coins to send a message.");
//     //   return;
//     // }
//     //
//     // // Deduct 8 coins BEFORE sending
//     // final newBalance = balance - 8;
//     // userVM.updateLocalCoinBalance(newBalance);
//     // userVM.updateUserCoinBalance(
//     //   newBalance,
//     //   "",           // staffId â€“ you can pass widget.conversationID if needed
//     //   8,            // coins spent
//     //   "0",
//     //   "chat",       // type
//     // );
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
//
//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Color(0xFF140810), Color(0xFF3A152A), Color(0xFF140810)],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   // â”€â”€â”€ Top Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
//                   // â”€â”€â”€ Messages List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//                   Expanded(
//                     child: ZIMKitMessageListView(
//                       conversationID: widget.conversationID,
//                       conversationType: widget.conversationType,
//                       scrollController: _scrollController,
//                     ),
//                   ),
//
//                   // â”€â”€â”€ Custom Input Bar with Coin Check â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
