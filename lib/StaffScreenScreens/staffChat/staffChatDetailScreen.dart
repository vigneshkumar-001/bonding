// lib/StaffScreenScreens/staffChat/View/StaffChatDetailScreen.dart

import 'dart:async';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:bonding_app/Reusable_Widgets/BondingNavigator.dart';
import 'package:bonding_app/StaffScreenScreens/staffChat/ViewModel/staff_chat_provider_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bonding_app/BondingScreens/Chat/Model/chat_message_model.dart';

class StaffChatDetailScreen extends StatefulWidget {
  final String staffId;
  final String userId;
  final String userName;

  const StaffChatDetailScreen({
    super.key,
    required this.staffId,
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
    final msg = _text.text.trim();
    if (msg.isEmpty) return;

    vm.sendMessage(msg);
    _text.clear();

    // if user is already near bottom -> keep them at bottom
    if (_userNearBottom) _scrollToBottom();
  }

  // ✅ Maintain position after loading older messages
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

  // ✅ Auto scroll when NEW message arrives (only if user near bottom)
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
                colors: [Color(0xFF140810), Color(0xFF3A152A), Color(0xFF140810)],
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
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 24),
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
                          key: ValueKey("center_loader"))
                          : (vm.messages.isEmpty
                          ? const Center(
                        key: ValueKey("empty"),
                        child: Text("No messages",
                            style: TextStyle(color: Colors.white70)),
                      )
                          : ListView.builder(
                        controller: _scroll,
                        padding:
                        const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        itemCount: vm.messages.length + 1,
                        itemBuilder: (context, index) {
                          // top loader for pagination
                          if (index == 0) {
                            return vm.loadingMore
                                ? const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                  CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            )
                                : const SizedBox(height: 6);
                          }

                          final m = vm.messages[index - 1];

                          // ✅ staff side: mine = staff
                          final isMine =
                              (m.senderRole ?? "").toLowerCase() ==
                                  "staff";

                          return _Bubble(
                            text: m.message ?? "",
                            isMine: isMine,
                            status: m.status,
                            onRetry: (m.status ==
                                ChatMsgStatus.failed)
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
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF231d1d),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization:
                              TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: "Message",
                                hintStyle:
                                TextStyle(color: Colors.grey[500]),
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
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 24),
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

// ✅ Center loader
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

// ✅ Bubble
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
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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

// ✅ Error Banner
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
}


/*
import 'dart:async';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Socket/socket_service.dart';

enum MsgStatus { sending, sent, failed }

class LocalMsg {
  final String tempId;
  final String? serverId; // ✅ add this
  final String sender;
  final String message;
  final DateTime at;
  final MsgStatus status;

  LocalMsg({
    required this.tempId,
    this.serverId,
    required this.sender,
    required this.message,
    required this.at,
    required this.status,
  });

  LocalMsg copyWith({MsgStatus? status, String? serverId}) => LocalMsg(
    tempId: tempId,
    serverId: serverId ?? this.serverId,
    sender: sender,
    message: message,
    at: at,
    status: status ?? this.status,
  );
}

class StaffChatDetailSocketScreen extends StatefulWidget {
  final String staffId; // can be memberID or mongoId (we will auto-fix)
  final String userId; // mongo user id
  final String userName;

  const StaffChatDetailSocketScreen({
    super.key,
    required this.staffId,
    required this.userId,
    required this.userName,
  });

  @override
  State<StaffChatDetailSocketScreen> createState() =>
      _StaffChatDetailSocketScreenState();
}

class _StaffChatDetailSocketScreenState
    extends State<StaffChatDetailSocketScreen> {
  final _svc = SocketService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final List<LocalMsg> _msgs = [];

  bool _joining = true;
  bool _joined = false;

  String? _error;
  Timer? _errTimer;

  StreamSubscription? _subJoined;
  StreamSubscription? _subReceive;
  StreamSubscription? _subError;
  StreamSubscription? _subConn;
  StreamSubscription? _subRegStaff;

  String? _staffMongoId; // ✅ final mongo staffId used for join/send/filter

  @override
  void initState() {
    super.initState();
    AppLogger.log.w(widget.userId);
    _initSocketFlow();
  }

  @override
  void dispose() {
    _errTimer?.cancel();
    _subJoined?.cancel();
    _subReceive?.cancel();
    _subError?.cancel();
    _subConn?.cancel();
    _subRegStaff?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _tempId() => "tmp_${DateTime.now().microsecondsSinceEpoch}";

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _error = msg);
    _errTimer?.cancel();
    _errTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _error = null);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _initSocketFlow() async {
    // 1) LISTEN FIRST (important)
    _subConn = _svc.connectionStream.listen((connected) {
      if (!connected && mounted) {
        setState(() {
          _joined = false;
          _joining = true;
        });
      }
    });

    // ✅ when staff registered, capture mongo id
    _subRegStaff = _svc.registeredStaffStream.listen((data) {
      if (!mounted) return;
      try {
        final m = (data is Map)
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final sid = (m["staffId"] ?? "").toString(); // mongo id
        if (sid.isNotEmpty) {
          _staffMongoId = sid;
        }
      } catch (_) {}
    });

    _subJoined = _svc.chatJoinedStream.listen((data) {
      if (!mounted) return;

      // optional safety: check join belongs to this userId
      try {
        final m = (data is Map)
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};
        final uid = (m["userId"] ?? "").toString();
        if (uid.isNotEmpty && uid != widget.userId) return;
      } catch (_) {}

      setState(() {
        _joined = true;
        _joining = false;
      });
      _scrollToBottom();
    });

    _subReceive = _svc.receiveMessageStream.listen((data) {
      if (!mounted) return;

      final msg = (data is Map)
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      final serverId = (msg["_id"] ?? "").toString();
      final message = (msg["message"] ?? "").toString();
      if (message.trim().isEmpty) return;

      // filter current chat
      final userId = (msg["userId"] ?? "").toString();
      if (userId.isNotEmpty && userId != widget.userId) return;

      final staffId = (msg["staffId"] ?? "").toString();
      final staffMongo = _staffMongoId ?? _svc.registeredStaffMongoId;
      if (staffMongo != null && staffId.isNotEmpty && staffId != staffMongo)
        return;

      // ✅ 1) hard dedupe by serverId
      if (serverId.isNotEmpty && _msgs.any((m) => m.serverId == serverId)) {
        return;
      }

      final senderRole = (msg["senderRole"] ?? msg["senderType"] ?? "user")
          .toString()
          .toLowerCase();
      final isStaff = senderRole == "staff";

      // ✅ 2) If this is my own message, update the last "sending" msg instead of adding new
      if (isStaff) {
        final idx = _msgs.lastIndexWhere(
          (m) =>
              m.sender == "staff" &&
              m.status == MsgStatus.sending &&
              m.message == message,
        );

        if (idx != -1) {
          setState(() {
            _msgs[idx] = _msgs[idx].copyWith(
              status: MsgStatus.sent,
              serverId: serverId.isEmpty ? null : serverId,
            );
          });
          _scrollToBottom();
          return;
        }
      }

      // ✅ 3) otherwise add new
      setState(() {
        _msgs.add(
          LocalMsg(
            tempId: _tempId(),
            serverId: serverId.isEmpty ? null : serverId,
            sender: isStaff ? "staff" : "user",
            message: message,
            at:
                DateTime.tryParse((msg["createdAt"] ?? "").toString()) ??
                DateTime.now(),
            status: MsgStatus.sent,
          ),
        );
      });
      _scrollToBottom();
    });

    _subError = _svc.chatErrorStream.listen((data) {
      if (!mounted) return;
      final msg = (data is Map)
          ? (data["message"] ?? data).toString()
          : data.toString();

      _showError(msg);

      // mark last sending message failed
      final idx = _msgs.lastIndexWhere(
        (m) => m.sender == "staff" && m.status == MsgStatus.sending,
      );
      if (idx != -1) {
        setState(
          () => _msgs[idx] = _msgs[idx].copyWith(status: MsgStatus.failed),
        );
      }
    });

    // 2) connect as staff
    setState(() {
      _joining = true;
      _joined = false;
    });

    await _svc.connectStaffRegister(
      baseUrl: "https://bondinig-ca63248fdb11.herokuapp.com",
    );

    final staffMongo = await _svc.waitForRegisteredStaffMongoId();

    // join with mongo id (not BON)
    await _svc.joinChatSafe(
      staffId: staffMongo ?? widget.staffId,
      userId: widget.userId,
    );
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    if (!_svc.isConnected || !_joined) {
      _showError("Socket not connected / room not joined");
      return;
    }

    final id = _tempId();

    setState(() {
      _msgs.add(
        LocalMsg(
          tempId: id,
          sender: "staff",
          message: text,
          at: DateTime.now(),
          status: MsgStatus.sending,
        ),
      );
    });

    _ctrl.clear();
    _scrollToBottom();

    final staffIdToUse =
        _staffMongoId ?? _svc.registeredStaffMongoId ?? widget.staffId;

    _svc.sendMessageWithAck(
      staffId: staffIdToUse,
      userId: widget.userId,
      message: text,
      onAck: (res) {
        final ok = (res is Map)
            ? ((res["status"] == true) || (res["ok"] == true))
            : true; // if ack not map, assume ok

        if (!mounted) return;
        final idx = _msgs.indexWhere((m) => m.tempId == id);
        if (idx == -1) return;

        setState(() {
          _msgs[idx] = _msgs[idx].copyWith(
            status: ok ? MsgStatus.sent : MsgStatus.failed,
          );
        });

        if (!ok) {
          _showError(
            (res is Map ? (res["message"] ?? "Send failed") : "Send failed")
                .toString(),
          );
        }
      },
    );
  }

  void _retry(LocalMsg m) {
    if (m.status != MsgStatus.failed) return;

    final idx = _msgs.indexWhere((x) => x.tempId == m.tempId);
    if (idx == -1) return;

    setState(() => _msgs[idx] = _msgs[idx].copyWith(status: MsgStatus.sending));

    final staffIdToUse =
        _staffMongoId ?? _svc.registeredStaffMongoId ?? widget.staffId;

    _svc.sendMessageWithAck(
      staffId: staffIdToUse,
      userId: widget.userId,
      message: m.message,
      onAck: (res) {
        final ok = (res is Map)
            ? ((res["status"] == true) || (res["ok"] == true))
            : true;

        if (!mounted) return;

        final i2 = _msgs.indexWhere((x) => x.tempId == m.tempId);
        if (i2 == -1) return;

        setState(() {
          _msgs[i2] = _msgs[i2].copyWith(
            status: ok ? MsgStatus.sent : MsgStatus.failed,
          );
        });

        if (!ok) {
          _showError(
            (res is Map ? (res["message"] ?? "Send failed") : "Send failed")
                .toString(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showErr = _error != null && _error!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF100A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100A0A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (_svc.isConnected && _joined)
                        ? const Color(0xFF00ed1c)
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  (_svc.isConnected && _joined) ? "Connected" : "Connecting...",
                  style: TextStyle(
                    fontSize: 12,
                    color: (_svc.isConnected && _joined)
                        ? const Color(0xFF00ed1c)
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: showErr ? null : 0,
            padding: showErr
                ? const EdgeInsets.fromLTRB(12, 8, 12, 6)
                : EdgeInsets.zero,
            child: showErr
                ? _ErrorBanner(
                    message: _error!,
                    onRetry: () {
                      _showError("Retrying...");
                      final staffIdToUse =
                          _staffMongoId ??
                          _svc.registeredStaffMongoId ??
                          widget.staffId;
                      _svc.joinChat(
                        staffId: staffIdToUse,
                        userId: widget.userId,
                      );
                    },
                    onClose: () => setState(() => _error = null),
                  )
                : const SizedBox.shrink(),
          ),

          if (_joining && !_joined && _msgs.isEmpty)
            const Expanded(
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  final isMine = m.sender == "staff";

                  return Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? const Color(0xFF2A1F2E)
                            : const Color(0xFF23171B),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: isMine
                              ? const Radius.circular(14)
                              : Radius.zero,
                          bottomRight: isMine
                              ? Radius.zero
                              : const Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              m.message,
                              style: const TextStyle(
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 8),
                            _StatusDot(
                              status: m.status,
                              onRetry: m.status == MsgStatus.failed
                                  ? () => _retry(m)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF1A1214),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- UI widgets ----------
class _StatusDot extends StatelessWidget {
  final MsgStatus status;
  final VoidCallback? onRetry;

  const _StatusDot({required this.status, this.onRetry});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MsgStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case MsgStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: const Icon(Icons.error, size: 18, color: Colors.redAccent),
        );
      case MsgStatus.sent:
      default:
        return const SizedBox(width: 2, height: 2);
    }
  }
}

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
}
*/

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
//     //   "",           // staffId – you can pass widget.conversationID if needed
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
