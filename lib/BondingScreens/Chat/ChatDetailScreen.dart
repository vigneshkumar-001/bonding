// lib/BondingScreens/Chat/ChatDetailScreen.dart
import 'dart:async';
import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';
import 'package:bonding_app/BondingScreens/Chat/ViewModel/chat_provider_vm.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String userId;

  const ChatDetailScreen({
    super.key,
    required this.staffId,
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
    _scroll.addListener(_onScroll);

    // scroll to bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(jump: true));
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
        vm.loadHistory(reset: false,isStaff: false);
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
                          vm.loadHistory(reset: true,isStaff: false);
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
        child: CircularProgressIndicator(strokeWidth: 2),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => onAfterBuildMaybeScroll());

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
                child: CircularProgressIndicator(strokeWidth: 2),
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
          onRetry: (m.status == ChatMsgStatus.failed) ? () => vm.retrySend(m) : null,
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

/*// lib/BondingScreens/Chat/ChatDetailSocketScreen.dart
import 'dart:async';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/Bonding_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String userId;

  const ChatDetailScreen({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.userId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _text = TextEditingController();

  final SocketService socket = SocketService();

  final List<_SocketMsg> _messages = [];

  StreamSubscription? _subMsg;
  StreamSubscription? _subConn;
  StreamSubscription? _subRegistered;
  StreamSubscription? _subJoined;
  StreamSubscription? _subError;
  StreamSubscription? _subBlocked;

  bool _joined = false;

  // ✅ DEDUPE server messages
  final Set<String> _seenServerIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectFlow());
  }

  Future<void> _connectFlow() async {
    // ✅ Cancel old subs (safety if screen rebuilds)
    await _cancelSubs();

    // 1) Connect + register user (SocketService handles token inside)
    await socket.connectUserRegister();

    // 2) MUST listeners list
    _subConn = socket.connectionStream.listen((connected) {
      if (!mounted) return;
      setState(() {});
      if (!connected) {
        _joined = false;
      }
    });

    _subRegistered = socket.registeredUserStream.listen((data) {
      // ✅ AFTER registered_user -> now safe to join chat room
      _joined = false;
      socket.joinChat(staffId: widget.staffId, userId: widget.userId);
    });

    _subJoined = socket.chatJoinedStream.listen((data) {
      if (!mounted) return;
      final m = (data is Map)
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      final staffId = (m["staffId"] ?? "").toString();
      final userId = (m["userId"] ?? "").toString();

      if (staffId == widget.staffId && userId == widget.userId) {
        _joined = true;
        setState(() {});
      }
    });

    _subError = socket.chatErrorStream.listen((e) {
      // optional UI toast
      // Utils.snackBarErrorMessage(e.toString());
    });

    _subBlocked = socket.chatBlockedStream.listen((e) {
      Utils.snackBarErrorMessage("Chat blocked by staff");
    });

    // 3) receive_message (DEDUP + replace local echo)
    _subMsg = socket.receiveMessageStream.listen((data) {
      if (!mounted) return;
      if (data is! Map) return;

      final m = Map<String, dynamic>.from(data);

      // Filter only this conversation
      final staffId = (m['staffId'] ?? "").toString();
      final userId = (m['userId'] ?? "").toString();
      if (staffId != widget.staffId || userId != widget.userId) return;

      // ✅ DEDUPE by DB _id
      final serverId = (m['_id'] ?? "").toString();
      if (serverId.isNotEmpty) {
        if (_seenServerIds.contains(serverId)) return;
        _seenServerIds.add(serverId);
      }

      final msgText = (m['message'] ?? "").toString();

      // backend uses senderRole: "user" | "staff"
      final senderRole = (m['senderRole'] ?? "").toString().toLowerCase();
      final isMine = senderRole == "user";

      DateTime t = DateTime.now();
      final raw = m['createdAt'];
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) t = parsed;
      }

      // ✅ If server echoes my message, REPLACE last local pending instead of adding duplicate
      if (isMine) {
        final idx = _messages.lastIndexWhere(
          (x) => x.isLocal == true && x.isMine == true && x.text == msgText,
        );
        if (idx != -1) {
          setState(() {
            _messages[idx] = _SocketMsg(
              id: serverId.isNotEmpty ? serverId : _messages[idx].id,
              text: msgText,
              isMine: true,
              time: t,
              isLocal: false,
              status: MsgStatus.sent,
            );
          });
          _scrollToBottom();
          return;
        }
      }

      setState(() {
        _messages.add(
          _SocketMsg(
            id: serverId.isNotEmpty
                ? serverId
                : "srv_${DateTime.now().microsecondsSinceEpoch}",
            text: msgText,
            isMine: isMine,
            time: t,
            isLocal: false,
            status: MsgStatus.sent,
          ),
        );
      });

      _scrollToBottom();
    });

    // If already connected, join quickly (in case registered came before listener)
    if (socket.isConnected) {
      socket.joinChat(staffId: widget.staffId, userId: widget.userId);
    }
  }

  Future<void> _cancelSubs() async {
    await _subMsg?.cancel();
    await _subConn?.cancel();
    await _subRegistered?.cancel();
    await _subJoined?.cancel();
    await _subError?.cancel();
    await _subBlocked?.cancel();
    _subMsg = null;
    _subConn = null;
    _subRegistered = null;
    _subJoined = null;
    _subError = null;
    _subBlocked = null;
  }

  @override
  void dispose() {
    _cancelSubs();
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;

    // OPTIONAL coin check
    // final userVM = context.read<UserViewModel>();
    // final balance = userVM.currentUser?.coinBalance ?? 0;
    // if (balance < 8) {
    //   Utils.snackBarErrorMessage("Insufficient balance! Need 8 coins to send a message.");
    //   return;
    // }

    final tempId = "tmp_${DateTime.now().millisecondsSinceEpoch}";

    // ✅ add local message instantly (PENDING)
    setState(() {
      _messages.add(
        _SocketMsg(
          id: tempId,
          text: text,
          isMine: true,
          time: DateTime.now(),
          isLocal: true,
          status: MsgStatus.sending,
        ),
      );
    });
    _text.clear();
    _scrollToBottom();

    // ✅ ensure connected
    if (!socket.isConnected) {
      // mark as failed, then try reconnect
      _markLocalFailed(tempId);
      socket.reconnect();
      return;
    }

    // ✅ ensure joined (best-effort)
    if (!_joined) {
      socket.joinChat(staffId: widget.staffId, userId: widget.userId);
      await Future.delayed(const Duration(milliseconds: 180));
    }

    // ✅ send to backend
    socket.sendMessage(
      staffId: widget.staffId,
      userId: widget.userId,
      message: text,
    );

    // NOTE:
    // When server echoes back receive_message with same "text",
    // we replace local pending message in listener above.
  }

  void _markLocalFailed(String tempId) {
    final idx = _messages.indexWhere((m) => m.id == tempId);
    if (idx == -1) return;
    setState(() {
      _messages[idx] = _messages[idx].copyWith(status: MsgStatus.failed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = socket.isConnected && _joined;

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
              // Top bar
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
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _Bubble(msg: _messages[i]),
                ),
              ),

              // Input
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
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
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
  }
}

// ----------------------------
// Message model
// ----------------------------
enum MsgStatus { sending, sent, failed }

class _SocketMsg {
  final String id;
  final String text;
  final bool isMine;
  final DateTime time;
  final bool isLocal;
  final MsgStatus status;

  _SocketMsg({
    required this.id,
    required this.text,
    required this.isMine,
    required this.time,
    this.isLocal = false,
    this.status = MsgStatus.sent,
  });

  _SocketMsg copyWith({
    String? id,
    String? text,
    bool? isMine,
    DateTime? time,
    bool? isLocal,
    MsgStatus? status,
  }) {
    return _SocketMsg(
      id: id ?? this.id,
      text: text ?? this.text,
      isMine: isMine ?? this.isMine,
      time: time ?? this.time,
      isLocal: isLocal ?? this.isLocal,
      status: status ?? this.status,
    );
  }
}

// ----------------------------
// Bubble UI
// ----------------------------
class _Bubble extends StatelessWidget {
  final _SocketMsg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bg = msg.isMine ? const Color(0xFF2A1F2E) : const Color(0xFF23171B);

    Widget statusIcon() {
      if (!msg.isMine) return const SizedBox.shrink();
      switch (msg.status) {
        case MsgStatus.sending:
          return const Padding(
            padding: EdgeInsets.only(left: 6),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        case MsgStatus.failed:
          return const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(Icons.error, size: 14, color: Colors.redAccent),
          );
        case MsgStatus.sent:
          return const SizedBox.shrink();
      }
    }

    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
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
            bottomLeft: msg.isMine ? const Radius.circular(15) : Radius.zero,
            bottomRight: msg.isMine ? Radius.zero : const Radius.circular(15),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
            ),
            statusIcon(),
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
//                 colors: [Color(0xFF140810), Color(0xFF3A152A), Color(0xFF140810)],
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
