

class BlockUserResponse {
  final bool status;
  final String message;
  final BlockedUserData? data;

  BlockUserResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory BlockUserResponse.fromJson(Map<String, dynamic> json) {
    return BlockUserResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] == null
          ? null
          : BlockedUserData.fromJson(Map<String, dynamic>.from(json['data'])),
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class BlockedUserData {
  final String id; // _id
  final String staffId;
  final String userId;
  final int? v; // __v

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? blockedAt;
  final DateTime? unblockedAt;

  final bool isBlocked;
  final String? reason;

  BlockedUserData({
    required this.id,
    required this.staffId,
    required this.userId,
    this.v,
    this.createdAt,
    this.updatedAt,
    this.blockedAt,
    this.unblockedAt,
    required this.isBlocked,
    this.reason,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  factory BlockedUserData.fromJson(Map<String, dynamic> json) {
    return BlockedUserData(
      id: (json['_id'] ?? '').toString(),
      staffId: (json['staffId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      v: json['__v'] is int ? json['__v'] as int : int.tryParse('${json['__v']}'),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      blockedAt: _parseDate(json['blockedAt']),
      unblockedAt: _parseDate(json['unblockedAt']),
      isBlocked: json['isBlocked'] == true,
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "staffId": staffId,
    "userId": userId,
    "__v": v,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "blockedAt": blockedAt?.toIso8601String(),
    "unblockedAt": unblockedAt?.toIso8601String(),
    "isBlocked": isBlocked,
    "reason": reason,
  };
}
