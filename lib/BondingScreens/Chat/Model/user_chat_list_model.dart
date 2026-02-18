// lib/BondingScreens/Chat/Model/user_chat_list_model.dart

class UserChatListResponse {
  final bool status;
  final String message;
  final List<UserChatListItem> data;
  final Pagination? pagination;

  UserChatListResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory UserChatListResponse.fromJson(Map<String, dynamic> json) {
    return UserChatListResponse(
      status: json["status"] == true,
      message: (json["message"] ?? "").toString(),
      data: (json["data"] as List? ?? [])
          .map((e) => UserChatListItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pagination: json["pagination"] == null
          ? null
          : Pagination.fromJson(Map<String, dynamic>.from(json["pagination"])),
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data.map((e) => e.toJson()).toList(),
    "pagination": pagination?.toJson(),
  };
}

class UserChatListItem {
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderRole; // "staff" | "user"
  final int unreadCount;

  final StaffInfo? staff;
  final String staffId;

  final bool isBlocked;
  final String blockReason;

  UserChatListItem({
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderRole,
    required this.unreadCount,
    required this.staff,
    required this.staffId,
    required this.isBlocked,
    required this.blockReason,
  });

  factory UserChatListItem.fromJson(Map<String, dynamic> json) {
    return UserChatListItem(
      lastMessage: (json["lastMessage"] ?? "").toString(),
      lastMessageAt: _tryParseDate(json["lastMessageAt"]),
      lastSenderRole: (json["lastSenderRole"] ?? "").toString(),
      unreadCount: _toInt(json["unreadCount"]),
      staff: json["staff"] == null
          ? null
          : StaffInfo.fromJson(Map<String, dynamic>.from(json["staff"])),
      staffId: (json["staffId"] ?? "").toString(),
      isBlocked: json["isBlocked"] == true,
      blockReason: (json["blockReason"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "lastMessage": lastMessage,
    "lastMessageAt": lastMessageAt?.toIso8601String(),
    "lastSenderRole": lastSenderRole,
    "unreadCount": unreadCount,
    "staff": staff?.toJson(),
    "staffId": staffId,
    "isBlocked": isBlocked,
    "blockReason": blockReason,
  };

  UserChatListItem copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderRole,
    int? unreadCount,
    StaffInfo? staff,
    String? staffId,
    bool? isBlocked,
    String? blockReason,
  }) {
    return UserChatListItem(
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderRole: lastSenderRole ?? this.lastSenderRole,
      unreadCount: unreadCount ?? this.unreadCount,
      staff: staff ?? this.staff,
      staffId: staffId ?? this.staffId,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
    );
  }
}

class StaffInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String image;
  final String memberId; // BON000...

  StaffInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
    required this.memberId,
  });

  factory StaffInfo.fromJson(Map<String, dynamic> json) {
    return StaffInfo(
      id: (json["_id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      phone: (json["phone"] ?? "").toString(),
      image: (json["image"] ?? "").toString(),
      memberId: (json["memberID"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "email": email,
    "phone": phone,
    "image": image,
    "memberID": memberId,
  };
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
    return Pagination(
      total: _toInt(json["total"]),
      page: _toInt(json["page"]),
      limit: _toInt(json["limit"]),
      totalPages: _toInt(json["totalPages"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "total": total,
    "page": page,
    "limit": limit,
    "totalPages": totalPages,
  };
}

// ---------------- helpers ----------------
DateTime? _tryParseDate(dynamic v) {
  final s = (v ?? "").toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}
