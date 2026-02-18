// support_ticket_list_response.dart

class SupportTicketListResponse {
  final bool status;
  final String message;
  final List<SupportTicketItem> data;
  final Pagination? pagination;

  SupportTicketListResponse({
    required this.status,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory SupportTicketListResponse.fromJson(Map<String, dynamic> json) {
    return SupportTicketListResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: (json['data'] as List?)
          ?.map((e) => SupportTicketItem.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.map((e) => e.toJson()).toList(),
    'pagination': pagination?.toJson(),
  };
}

class SupportTicketItem {
  final String id;
  final String title;
  final String description;
  final String status; // open/closed etc.
  final DateTime? createdAt;

  SupportTicketItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory SupportTicketItem.fromJson(Map<String, dynamic> json) {
    return SupportTicketItem(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'description': description,
    'status': status,
    'createdAt': createdAt?.toIso8601String(),
  };

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v, {int def = 0}) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? def;

    return Pagination(
      total: _toInt(json['total']),
      page: _toInt(json['page'], def: 1),
      limit: _toInt(json['limit'], def: 20),
      totalPages: _toInt(json['totalPages'], def: 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'page': page,
    'limit': limit,
    'totalPages': totalPages,
  };
}
