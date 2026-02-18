// support_ticket_create_response.dart

class SupportTicketCreateResponse {
  final bool status;
  final String message;
  final SupportTicketData? data;

  SupportTicketCreateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory SupportTicketCreateResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketCreateResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? SupportTicketData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

class SupportTicketData {
  final String id;
  final String title;
  final String description;
  final String message; // top-level message in data
  final List<String> media;
  final List<TicketMessage> messages;

  final String createdByType;
  final String createdById;

  final String status; // "open" etc.
  final String? updatedBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  SupportTicketData({
    required this.id,
    required this.title,
    required this.description,
    required this.message,
    required this.media,
    required this.messages,
    required this.createdByType,
    required this.createdById,
    required this.status,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory SupportTicketData.fromJson(Map<String, dynamic> json) {
    return SupportTicketData(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      media:
          (json['media'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      messages:
          (json['messages'] as List?)
              ?.whereType<Map>()
              .map((e) => TicketMessage.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      createdByType: (json['createdByType'] ?? '').toString(),
      createdById: (json['createdById'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      updatedBy: json['updatedBy']?.toString(),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
      v: json['__v'] is int
          ? json['__v'] as int
          : int.tryParse('${json['__v']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'message': message,
    'media': media,
    'messages': messages.map((e) => e.toJson()).toList(),
    'createdByType': createdByType,
    'createdById': createdById,
    'status': status,
    'updatedBy': updatedBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': v,
  };

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class TicketMessage {
  final String senderType; // staff/user
  final String senderId;
  final String message;
  final List<String> media;
  final DateTime? createdAt;

  TicketMessage({
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.media,
    this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      senderType: (json['senderType'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      media:
          (json['media'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt: SupportTicketData._tryParseDate(json['createdAt']),
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
