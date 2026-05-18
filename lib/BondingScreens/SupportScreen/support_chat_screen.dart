import 'dart:io';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Bonding_Utils/ColorHandlers/Apptheme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Reusable_Widgets/Common_AppBar/common_app_bar.dart';
import 'ViewModel/ticket_history_vm.dart';
import 'ViewModel/ticket_message_vm.dart';

enum LocalMsgStatus { sending, sent, failed }

class LocalChatItem {
  final String localId;
  final String text;

  final File? localImage;
  final DateTime time;
  LocalMsgStatus status;

  LocalChatItem({
    required this.localId,

    required this.text,
    required this.localImage,
    required this.time,
    required this.status,
  });
}

class SupportChatScreen extends StatefulWidget {
  final String ticketId;
  final String? subjects;
  final String? date;
  final bool isStaff;
  const SupportChatScreen({
    super.key,
    required this.ticketId,
    required this.isStaff,
    this.subjects,
    this.date,
  });

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scroll = ScrollController();

  final List<LocalChatItem> _localQueue = [];
  File? _selectedImage;

  // used to auto scroll when new server msgs arrive
  int _lastRenderedCount = 0;

  static const Color _bg = Color(0xFF100A0A);
  static const Color _panel = Color(0xFF1A1214);
  static const Color _incoming = Color(0xFF23171B);
  static const Color _outgoing = Color(0xFF2A1F2E);
  static const Color _hint = Color(0xFF919199);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppLogger.log.w(widget.isStaff);
      final historyVM = context.read<TicketHistoryVM>();
      historyVM.setActiveTicket(widget.ticketId);
      await historyVM.fetchHistory(
        widget.ticketId,
        showLoader: true,
        isStaff: widget.isStaff,
      );

      // after first load, go bottom
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _localId() => "${DateTime.now().microsecondsSinceEpoch}";

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;

    if (image != null) {
      final path = image.path.toLowerCase();
      final ok =
          path.endsWith('.png') ||
          path.endsWith('.jpg') ||
          path.endsWith('.jpeg');
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only PNG, JPG, JPEG formats are supported'),
          ),
        );
        return;
      }
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _sendMessage({LocalChatItem? retryItem}) async {
    final text = retryItem != null
        ? retryItem.text
        : _messageController.text.trim();
    final img = retryItem != null ? retryItem.localImage : _selectedImage;

    if (text.isEmpty && img == null) return;

    LocalChatItem local;
    if (retryItem != null) {
      local = retryItem;
      setState(() {
        local.status = img != null
            ? LocalMsgStatus.sending
            : LocalMsgStatus.sent;
      });
    } else {
      local = LocalChatItem(
        localId: _localId(),
        text: text,
        localImage: img,
        time: DateTime.now(),
        status: img != null
            ? LocalMsgStatus.sending
            : LocalMsgStatus.sent, // ✅ loader only for images
      );

      setState(() {
        _localQueue.add(local);
        _messageController.clear();
        _selectedImage = null;
      });
    }

    _scrollToBottom();

    // ✅ Send API (no UI refresh)
    final ok = await context.read<TicketMessageVM>().sendMessage(
      isStaff: widget.isStaff,
      ticketId: widget.ticketId,
      message: text.isEmpty ? " " : text,
      mediaUrls: const [], // later add uploaded url list
    );

    if (!mounted) return;

    if (!ok) {
      setState(() => local.status = LocalMsgStatus.failed);
      return;
    }

    setState(() => local.status = LocalMsgStatus.sent);

    // ✅ silent refresh (NO BLINK)
    await context.read<TicketHistoryVM>().silentRefresh(
      widget.ticketId,
      isStaff: widget.isStaff,
    );

    // ✅ remove local duplicates if server already has it
    _dedupeLocal();

    _scrollToBottom();
  }

  void _dedupeLocal() {
    final server = context.read<TicketHistoryVM>().messages;

    bool existsOnServer(LocalChatItem l) {
      if (l.text.trim().isEmpty) return false; // image-only skip
      for (final m in server) {
        final sender = (m.senderType ?? "").toLowerCase();
        final mineSenderOk = widget.isStaff
            ? (sender == "admin" || sender == "staff")
            : (sender == "user");
        if (!mineSenderOk) continue;

        if ((m.message ?? "").trim() != l.text.trim()) continue;

        final st = m.createdAt?.toLocal();
        if (st == null) continue;

        final diff = st.difference(l.time).inSeconds.abs();
        if (diff <= 180) return true;
      }
      return false;
    }

    _localQueue.removeWhere(
      (l) => l.status != LocalMsgStatus.failed && existsOnServer(l),
    );
    setState(() {});
  }

  Widget _sideStatus(LocalChatItem local) {
    // ✅ no tick
    if (local.status == LocalMsgStatus.failed) {
      return InkWell(
        onTap: () => _sendMessage(retryItem: local),
        child: const Icon(
          Icons.error_outline,
          color: Colors.redAccent,
          size: 18,
        ),
      );
    }

    // ✅ loader only for image
    if (local.status == LocalMsgStatus.sending && local.localImage != null) {
      return const SizedBox(
        height: 14,
        width: 14,
        child: const AppLoadingIndicator(radius: 10, color: Colors.white70),
      );
    }

    return const SizedBox(width: 18);
  }

  Widget _bubble({
    required bool isMine,
    required String text,
    required DateTime? time,
    File? localImage,
    List<String> mediaUrls = const [],
    Widget? sideStatus,
  }) {
    final bubbleColor = isMine ? _outgoing : _incoming;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: isMine ? const Radius.circular(15) : Radius.zero,
                  bottomRight: isMine ? Radius.zero : const Radius.circular(15),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ local image (sending)
                  if (localImage != null) ...[
                    _imageBox(
                      child: Image.file(
                        localImage,
                        height: 160,
                        width: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (text.trim().isNotEmpty) const SizedBox(height: 8),
                  ],

                  // ✅ server images (cached)
                  if (mediaUrls.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: mediaUrls
                          .map((url) => _cachedImage(url))
                          .toList(),
                    ),
                    if (text.trim().isNotEmpty) const SizedBox(height: 8),
                  ],

                  if (text.trim().isNotEmpty)
                    Text(
                      text.trim(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),

                  const SizedBox(height: 6),
                  SizedBox(
                    height: 18,
                    child: Text(
                      time == null
                          ? "-"
                          : DateFormat('hh:mm a').format(time.toLocal()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine && sideStatus != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: sideStatus,
            ),
        ],
      ),
    );
  }

  Widget _imageBox({required Widget child}) {
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: child);
  }

  Widget _cachedImage(String url) {
    return _imageBox(
      child: CachedNetworkImage(
        imageUrl: url,
        height: 160,
        width: 160,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          height: 160,
          width: 160,
          alignment: Alignment.center,
          child: const SizedBox(
            height: 18,
            width: 18,
            child: const AppLoadingIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
        ),
        errorWidget: (context, _, __) => Container(
          height: 160,
          width: 160,
          alignment: Alignment.center,
          color: Colors.white.withOpacity(0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.broken_image_outlined, color: Colors.redAccent),
              SizedBox(height: 6),
              Text(
                "Image failed",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonAppBar(
        title: 'Chat With Support',
        usePaddedLeading: true,
        bg: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subjects ?? "",
                              style: const TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Created on ${widget.date ?? ""}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: Consumer<TicketHistoryVM>(
                builder: (context, vm, _) {
                  // ✅ only first loader
                  if (vm.isLoading && vm.messages.isEmpty) {
                    return const Center(
                      child: const AppLoadingIndicator(color: Colors.white),
                    );
                  }

                  if (vm.errorMessage != null && vm.messages.isEmpty) {
                    return Center(
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    );
                  }

                  final mergedCount = vm.messages.length + _localQueue.length;

                  // ✅ empty means show nothing (no "No messages")
                  if (mergedCount == 0) return const SizedBox.shrink();

                  // ✅ auto scroll if new msgs arrived
                  if (mergedCount != _lastRenderedCount) {
                    _lastRenderedCount = mergedCount;
                    _scrollToBottom();
                  }

                  return ListView.builder(
                    controller: _scroll,
                    reverse: false, // old -> new (latest bottom)
                    padding: const EdgeInsets.only(bottom: 6),
                    itemCount: mergedCount,
                    itemBuilder: (context, index) {
                      // server msg
                      if (index < vm.messages.length) {
                        final m = vm.messages[index];
                        final sender = (m.senderType ?? "").toLowerCase();

                        final isMine = widget.isStaff
                            ? (sender == "admin" || sender == "staff")
                            : (sender == "user");

                        return _bubble(
                          isMine: isMine,
                          text: (m.message ?? ""),
                          time: m.createdAt,
                          mediaUrls: (m.media ?? const []).cast<String>(),
                        );
                      }

                      // local msg
                      final local = _localQueue[index - vm.messages.length];
                      return _bubble(
                        isMine: true,
                        text: local.text,
                        time: local.time,
                        localImage: local.localImage,
                        sideStatus: _sideStatus(local),
                      );
                    },
                  );
                },
              ),
            ),

            // composer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                height: 110,
                                width: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            maxLines: null,
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              hintText: 'Type message...',
                              hintStyle: TextStyle(color: _hint),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.cloud_upload,
                            size: 26,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: Apptheme.buttonGradient,
                          ),
                          child: IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
