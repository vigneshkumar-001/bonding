class BlockedListResponse {
  final bool status;
  final String message;
  final int count;
  final List<BlockedItem> data;

  BlockedListResponse({
    required this.status,
    required this.message,
    required this.count,
    required this.data,
  });

  factory BlockedListResponse.fromJson(Map<String, dynamic> json) {
    return BlockedListResponse(
      status: json["status"] == true,
      message: (json["message"] ?? "").toString(),
      count: (json["count"] ?? 0) is int
          ? (json["count"] as int)
          : int.tryParse("${json["count"]}") ?? 0,
      data: (json["data"] as List? ?? [])
          .map((e) => BlockedItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BlockedItem {
  final String id;

  /// staffId can be String OR Object
  final String? staffIdStr;
  final PersonInfo? staffObj;

  /// userId can be String OR Object
  final String? userIdStr;
  final PersonInfo? userObj;

  final bool isBlocked;
  final String reason;

  final DateTime? blockedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? unblockedAt;

  BlockedItem({
    required this.id,
    required this.staffIdStr,
    required this.staffObj,
    required this.userIdStr,
    required this.userObj,
    required this.isBlocked,
    required this.reason,
    required this.blockedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.unblockedAt,
  });

  factory BlockedItem.fromJson(Map<String, dynamic> json) {
    final staffRaw = json["staffId"];
    final userRaw = json["userId"];

    PersonInfo? staffObj;
    String? staffIdStr;

    if (staffRaw is Map) {
      staffObj = PersonInfo.fromJson(Map<String, dynamic>.from(staffRaw));
    } else if (staffRaw != null) {
      staffIdStr = staffRaw.toString();
    }

    PersonInfo? userObj;
    String? userIdStr;

    if (userRaw is Map) {
      userObj = PersonInfo.fromJson(Map<String, dynamic>.from(userRaw));
    } else if (userRaw != null) {
      userIdStr = userRaw.toString();
    }

    return BlockedItem(
      id: (json["_id"] ?? "").toString(),
      staffIdStr: staffIdStr,
      staffObj: staffObj,
      userIdStr: userIdStr,
      userObj: userObj,
      isBlocked: json["isBlocked"] == true,
      reason: (json["reason"] ?? "").toString(),
      blockedAt: _tryDate(json["blockedAt"]),
      createdAt: _tryDate(json["createdAt"]),
      updatedAt: _tryDate(json["updatedAt"]),
      unblockedAt: _tryDate(json["unblockedAt"]),
    );
  }

  static DateTime? _tryDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  // =========================================================
  // ✅ Helpers for UI (same screen reuse)
  // =========================================================

  /// show whichever object exists (userObj OR staffObj)
  PersonInfo? get displayPerson => userObj ?? staffObj;

  /// mongo id for actions (unblock etc.)
  /// if userObj exists -> userObj.id else staffObj.id else string ids
  String get displayId =>
      (displayPerson?.id ?? userIdStr ?? staffIdStr ?? "").toString();

  String get displayName {
    final name = (displayPerson?.name ?? "").trim();
    return name.isNotEmpty ? name : "Unknown";
  }

  String get displayImage => (displayPerson?.image ?? "").trim();

  String get displayMemberId => (displayPerson?.memberID ?? "").trim();

  String get displayPhone => (displayPerson?.phone ?? "").trim();
}

class PersonInfo {
  final String id;
  final String phone;
  final String memberID;
  final String name;
  final String image;

  // staff-only field (sometimes present)
  final String email;

  PersonInfo({
    required this.id,
    required this.phone,
    required this.memberID,
    required this.name,
    required this.image,
    required this.email,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      id: (json["_id"] ?? "").toString(),
      phone: (json["phone"] ?? "").toString(),
      memberID: (json["memberID"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      image: (json["image"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
    );
  }
}


// // lib/StaffScreenScreens/staffChat/Model/blocked_users_list_model.dart
//
// class BlockedUsersListResponse {
//   final bool status;
//   final String message;
//   final int count;
//   final List<BlockedUserItem> data;
//
//   BlockedUsersListResponse({
//     required this.status,
//     required this.message,
//     required this.count,
//     required this.data,
//   });
//
//   factory BlockedUsersListResponse.fromJson(Map<String, dynamic> json) {
//     return BlockedUsersListResponse(
//       status: json["status"] == true,
//       message: (json["message"] ?? "").toString(),
//       count: (json["count"] ?? 0) is int
//           ? json["count"]
//           : int.tryParse("${json["count"]}") ?? 0,
//       data: (json["data"] as List? ?? [])
//           .map((e) => BlockedUserItem.fromJson(Map<String, dynamic>.from(e)))
//           .toList(),
//     );
//   }
// }
//
// class BlockedUserItem {
//   final String id;
//   final String staffId;
//   final BlockedUserInfo userId; // populated object
//   final bool isBlocked;
//   final String reason;
//   final DateTime? blockedAt;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;
//   final DateTime? unblockedAt;
//
//   BlockedUserItem({
//     required this.id,
//     required this.staffId,
//     required this.userId,
//     required this.isBlocked,
//     required this.reason,
//     this.blockedAt,
//     this.createdAt,
//     this.updatedAt,
//     this.unblockedAt,
//   });
//
//   factory BlockedUserItem.fromJson(Map<String, dynamic> json) {
//     return BlockedUserItem(
//       id: (json["_id"] ?? "").toString(),
//       staffId: (json["staffId"] ?? "").toString(),
//       userId: BlockedUserInfo.fromJson(
//         Map<String, dynamic>.from(json["userId"] ?? {}),
//       ),
//       isBlocked: json["isBlocked"] == true,
//       reason: (json["reason"] ?? "").toString(),
//       blockedAt: _tryDate(json["blockedAt"]),
//       createdAt: _tryDate(json["createdAt"]),
//       updatedAt: _tryDate(json["updatedAt"]),
//       unblockedAt: _tryDate(json["unblockedAt"]),
//     );
//   }
//
//   static DateTime? _tryDate(dynamic v) {
//     if (v == null) return null;
//     final s = v.toString();
//     return DateTime.tryParse(s);
//   }
// }
//
// class BlockedUserInfo {
//   final String id;
//   final String phone;
//   final String memberID;
//   final String name;
//   final String image;
//
//   BlockedUserInfo({
//     required this.id,
//     required this.phone,
//     required this.memberID,
//     required this.name,
//     required this.image,
//   });
//
//   factory BlockedUserInfo.fromJson(Map<String, dynamic> json) {
//     return BlockedUserInfo(
//       id: (json["_id"] ?? "").toString(),
//       phone: (json["phone"] ?? "").toString(),
//       memberID: (json["memberID"] ?? "").toString(),
//       name: (json["name"] ?? "").toString(),
//       image: (json["image"] ?? "").toString(),
//     );
//   }
// }
