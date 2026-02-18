// support_ticket_add_message_response.dart

class SupportTicketAddMessageResponse {
  final bool status;
  final String message;
  final SupportTicketAddMessageData? data;

  SupportTicketAddMessageResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory SupportTicketAddMessageResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketAddMessageResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? SupportTicketAddMessageData.fromJson(
        json['data'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

class SupportTicketAddMessageData {
  final String id;
  final String title;
  final String description;
  final String? messageText; // top-level "message"
  final List<String> media;
  final String? createdByType; // user/staff
  final String? createdById;
  final String status; // open/closed etc.
  final dynamic updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final List<TicketMessageItem> messages;

  SupportTicketAddMessageData({
    required this.id,
    required this.title,
    required this.description,
    this.messageText,
    required this.media,
    this.createdByType,
    this.createdById,
    required this.status,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.v,
    required this.messages,
  });

  factory SupportTicketAddMessageData.fromJson(Map<String, dynamic> json) {
    return SupportTicketAddMessageData(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      messageText: json['message']?.toString(),
      media: (json['media'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdByType: json['createdByType']?.toString(),
      createdById: json['createdById']?.toString(),
      status: (json['status'] ?? '').toString(),
      updatedBy: json['updatedBy'],
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
      v: _tryParseInt(json['__v']),
      messages: (json['messages'] as List?)
          ?.map((e) => TicketMessageItem.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'message': messageText,
    'media': media,
    'createdByType': createdByType,
    'createdById': createdById,
    'status': status,
    'updatedBy': updatedBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': v,
    'messages': messages.map((e) => e.toJson()).toList(),
  };

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static int? _tryParseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}

class TicketMessageItem {
  final String? senderType; // user/staff
  final String? senderId;
  final String message;
  final List<String> media;
  final DateTime? createdAt;

  TicketMessageItem({
    this.senderType,
    this.senderId,
    required this.message,
    required this.media,
    this.createdAt,
  });

  factory TicketMessageItem.fromJson(Map<String, dynamic> json) {
    return TicketMessageItem(
      senderType: json['senderType']?.toString(),
      senderId: json['senderId']?.toString(),
      message: (json['message'] ?? '').toString(),
      media: (json['media'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: SupportTicketAddMessageData._tryParseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'senderType': senderType,
    'senderId': senderId,
    'message': message,
    'media': media,
    'createdAt': createdAt?.toIso8601String(),
  };
}
