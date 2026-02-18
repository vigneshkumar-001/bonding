// ticket_message_history_response.dart

class TicketMessageHistoryResponse {
  final bool status;
  final String message;
  final TicketHistoryData? data;

  TicketMessageHistoryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory TicketMessageHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TicketMessageHistoryResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? TicketHistoryData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data?.toJson(),
  };
}

class TicketHistoryData {
  final String id;
  final String title;
  final String description;
  final String status; // open/closed etc.
  final DateTime? createdAt;
  final List<TicketHistoryMessage> messages;

  TicketHistoryData({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
    required this.messages,
  });

  factory TicketHistoryData.fromJson(Map<String, dynamic> json) {
    return TicketHistoryData(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: _tryParseDate(json['createdAt']),
      messages: (json['messages'] as List?)
          ?.map((e) => TicketHistoryMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'status': status,
    'createdAt': createdAt?.toIso8601String(),
    'messages': messages.map((e) => e.toJson()).toList(),
  };

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class TicketHistoryMessage {
  final String? senderType; // staff/user (if backend sends)
  final String? senderId;
  final String message;
  final List<String> media;
  final DateTime? createdAt;

  TicketHistoryMessage({
    this.senderType,
    this.senderId,
    required this.message,
    required this.media,
    this.createdAt,
  });

  factory TicketHistoryMessage.fromJson(Map<String, dynamic> json) {
    return TicketHistoryMessage(
      senderType: json['senderType']?.toString(),
      senderId: json['senderId']?.toString(),
      message: (json['message'] ?? '').toString(),
      media: (json['media'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: TicketHistoryData._tryParseDate(json['createdAt']),
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
