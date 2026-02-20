// lib/models/user_call_history_model.dart

class UserCallHistoryResponse {
  final bool status;
  final String message;
  final List<UserCallHistoryItem> data;

  const UserCallHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserCallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return UserCallHistoryResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Failed to fetch call history',
      data: (json['data'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(UserCallHistoryItem.fromJson)
          .toList() ??
          const <UserCallHistoryItem>[],
    );
  }
}

enum CallType { audio, video, chat, message, unknown }
enum CallSource { call, message, unknown }

CallType callTypeFromJson(dynamic v) {
  final s = v?.toString().toLowerCase().trim();
  switch (s) {
    case 'audio':
      return CallType.audio;
    case 'video':
      return CallType.video;
    case 'chat':
      return CallType.chat;
    case 'message':
      return CallType.message;
    default:
      return CallType.unknown;
  }
}

CallSource callSourceFromJson(dynamic v) {
  final s = v?.toString().toLowerCase().trim();
  switch (s) {
    case 'call':
      return CallSource.call;
    case 'message':
      return CallSource.message;
    default:
      return CallSource.unknown;
  }
}

class UserCallHistoryItem {
  final String id;

  /// Durations sometimes come as "61" string, sometimes 0
  final int callDurationSeconds;

  final CallType callType;
  final CallSource source;
  final String currency;

  /// User fields (some responses have email, some don't)
  final String userId;
  final String userName;
  final String userPhone;
  final String userMemberID;
  final String? userEmail;
  final String? userImage;

  /// Money (keep as num because decimals exist)
  final num userSpentAmount;
  final num? userRemainingBalance;

  /// Staff fields
  final String staffId;
  final String staffName;
  final String staffPhone;
  final String staffMemberID;
  final String? staffEmail;
  final String? staffImage;

  /// Revenue split (optional in some history entries)
  final num staffEarned;
  final num staffSharePercent;
  final num adminEarnedAmount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserCallHistoryItem({
    required this.id,
    required this.callDurationSeconds,
    required this.callType,
    required this.source,
    required this.currency,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userMemberID,
    required this.staffId,
    required this.staffName,
    required this.staffPhone,
    required this.staffMemberID,
    required this.userSpentAmount,
    required this.staffEarned,
    required this.staffSharePercent,
    required this.adminEarnedAmount,
    this.userEmail,
    this.userImage,
    this.userRemainingBalance,
    this.staffEmail,
    this.staffImage,
    this.createdAt,
    this.updatedAt,
  });

  factory UserCallHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    int _int(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    num _num(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? 0;
    }

    num? _numOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    return UserCallHistoryItem(
      id: json['_id']?.toString() ?? '',
      callDurationSeconds: _int(json['callDuration']),
      callType: callTypeFromJson(json['callType']),
      source: callSourceFromJson(json['source']),
      currency: json['currency']?.toString() ?? 'INR',

      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      userMemberID: json['userMemberID']?.toString() ?? '',
      userEmail: json['userEmail']?.toString(),
      userImage: json['userImage']?.toString(),

      userSpentAmount: _num(json['userSpentAmount']),
      userRemainingBalance: _numOrNull(json['userRemainingBalance']),

      staffId: json['staffId']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? '',
      staffPhone: json['staffPhone']?.toString() ?? '',
      staffMemberID: json['staffMemberID']?.toString() ?? '',
      staffEmail: json['staffEmail']?.toString(),
      staffImage: json['staffImage']?.toString(),

      staffEarned: _num(json['staffEarned']),
      staffSharePercent: _num(json['staffSharePercent']),
      adminEarnedAmount: _num(json['adminEarnedAmount']),

      createdAt: _dt(json['createdAt']),
      updatedAt: _dt(json['updatedAt']),
    );
  }
}
