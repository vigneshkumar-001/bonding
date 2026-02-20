class UnblockUserResponse {
  final bool status;
  final String message;
  final UnblockUserData? data;

  UnblockUserResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory UnblockUserResponse.fromJson(Map<String, dynamic> json) {
    return UnblockUserResponse(
      status: json["status"] == true,
      message: (json["message"] ?? "").toString(),
      data: json["data"] == null
          ? null
          : UnblockUserData.fromJson(Map<String, dynamic>.from(json["data"])),
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class UnblockUserData {
  final String id;
  final String staffId;
  final String userId;
  final bool isBlocked;
  final String reason;
  final DateTime? blockedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? unblockedAt;
  final int? v;

  UnblockUserData({
    required this.id,
    required this.staffId,
    required this.userId,
    required this.isBlocked,
    required this.reason,
    this.blockedAt,
    this.createdAt,
    this.updatedAt,
    this.unblockedAt,
    this.v,
  });

  factory UnblockUserData.fromJson(Map<String, dynamic> json) {
    DateTime? parseDT(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return UnblockUserData(
      id: (json["_id"] ?? "").toString(),
      staffId: (json["staffId"] ?? "").toString(),
      userId: (json["userId"] ?? "").toString(),
      isBlocked: json["isBlocked"] == true,
      reason: (json["reason"] ?? "").toString(),
      blockedAt: parseDT(json["blockedAt"]),
      createdAt: parseDT(json["createdAt"]),
      updatedAt: parseDT(json["updatedAt"]),
      unblockedAt: parseDT(json["unblockedAt"]),
      v: json["__v"] is int ? json["__v"] : int.tryParse("${json["__v"]}"),
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "staffId": staffId,
    "userId": userId,
    "isBlocked": isBlocked,
    "reason": reason,
    "blockedAt": blockedAt?.toIso8601String(),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "unblockedAt": unblockedAt?.toIso8601String(),
    "__v": v,
  };
}
