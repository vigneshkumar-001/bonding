class ChatMessageModel {
  final String id; // _id or local tmp id
  final String? staffId;
  final String? userId;
  final String? senderRole; // user/staff
  final String? message;
  final DateTime createdAt;

  // ✅ local message helpers
  final bool isLocal;
  final ChatMsgStatus status;

  ChatMessageModel({
    required this.id,
    required this.createdAt,
    this.staffId,
    this.userId,
    this.senderRole,
    this.message,
    this.isLocal = false,
    this.status = ChatMsgStatus.sent,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json["_id"] ?? "").toString(),
      staffId: (json["staffId"] ?? "").toString(),
      userId: (json["userId"] ?? "").toString(),
      senderRole: (json["senderRole"] ?? "").toString(),
      message: (json["message"] ?? "").toString(),
      createdAt: DateTime.tryParse((json["createdAt"] ?? "").toString()) ??
          DateTime.now(),
      isLocal: false,
      status: ChatMsgStatus.sent,
    );
  }

  factory ChatMessageModel.fromSocket(Map<String, dynamic> m) {
    return ChatMessageModel(
      id: (m["_id"] ?? "").toString(),
      staffId: (m["staffId"] ?? "").toString(),
      userId: (m["userId"] ?? "").toString(),
      senderRole: (m["senderRole"] ?? "").toString(),
      message: (m["message"] ?? "").toString(),
      createdAt: DateTime.tryParse((m["createdAt"] ?? "").toString()) ??
          DateTime.now(),
      isLocal: false,
      status: ChatMsgStatus.sent,
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? staffId,
    String? userId,
    String? senderRole,
    String? message,
    DateTime? createdAt,
    bool? isLocal,
    ChatMsgStatus? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      userId: userId ?? this.userId,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isLocal: isLocal ?? this.isLocal,
      status: status ?? this.status,
    );
  }
}

enum ChatMsgStatus { sending, sent, failed }
