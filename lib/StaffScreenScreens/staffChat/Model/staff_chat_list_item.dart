class StaffChatListResponse {
  final bool status;
  final String message;
  final List<StaffChatItem> data;
  final Pagination pagination;

  StaffChatListResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory StaffChatListResponse.fromJson(Map<String, dynamic> json) {
    return StaffChatListResponse(
      status: json["status"] == true,
      message: (json["message"] ?? "").toString(),
      data: (json["data"] as List? ?? [])
          .map((e) => StaffChatItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pagination: Pagination.fromJson(
        Map<String, dynamic>.from(json["pagination"] ?? {}),
      ),
    );
  }
}

class StaffChatItem {
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderRole;
  final int unreadCount;

  final StaffChatUser? user;
  final String userId;

  final bool isBlocked;
  final String blockReason;

  StaffChatItem({
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderRole,
    required this.unreadCount,
    required this.user,
    required this.userId,
    required this.isBlocked,
    required this.blockReason,
  });

  String get userName => (user?.name ?? "").trim().isNotEmpty ? user!.name : "User";
  String get userImage => (user?.image ?? "").toString();

  factory StaffChatItem.fromJson(Map<String, dynamic> json) {
    return StaffChatItem(
      lastMessage: (json["lastMessage"] ?? "").toString(),
      lastMessageAt: json["lastMessageAt"] != null
          ? DateTime.tryParse(json["lastMessageAt"].toString())
          : null,
      lastSenderRole: (json["lastSenderRole"] ?? "").toString(),
      unreadCount: (json["unreadCount"] ?? 0) is int
          ? json["unreadCount"] as int
          : int.tryParse(json["unreadCount"].toString()) ?? 0,
      user: json["user"] != null
          ? StaffChatUser.fromJson(Map<String, dynamic>.from(json["user"]))
          : null,
      userId: (json["userId"] ?? "").toString(),
      isBlocked: json["isBlocked"] == true,
      blockReason: (json["blockReason"] ?? "").toString(),
    );
  }

  // ✅ THIS is what your VM needs
  StaffChatItem copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastSenderRole,
    int? unreadCount,
    StaffChatUser? user,
    String? userId,
    bool? isBlocked,
    String? blockReason,
  }) {
    return StaffChatItem(
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastSenderRole: lastSenderRole ?? this.lastSenderRole,
      unreadCount: unreadCount ?? this.unreadCount,
      user: user ?? this.user,
      userId: userId ?? this.userId,
      isBlocked: isBlocked ?? this.isBlocked,
      blockReason: blockReason ?? this.blockReason,
    );
  }
}

class StaffChatUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String image;
  final String memberID;

  StaffChatUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.image,
    required this.memberID,
  });

  factory StaffChatUser.fromJson(Map<String, dynamic> json) {
    return StaffChatUser(
      id: (json["_id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      phone: (json["phone"] ?? "").toString(),
      image: (json["image"] ?? "").toString(),
      memberID: (json["memberID"] ?? "").toString(),
    );
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
    int toInt(dynamic v, int def) => v is int ? v : int.tryParse("$v") ?? def;

    return Pagination(
      total: toInt(json["total"], 0),
      page: toInt(json["page"], 1),
      limit: toInt(json["limit"], 12),
      totalPages: toInt(json["totalPages"], 1),
    );
  }
}
