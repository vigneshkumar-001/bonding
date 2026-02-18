class CallHistoryResponse {
  final bool status;
  final String message;
  final List<CallHistoryItem> data;

  CallHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = (raw is List)
        ? raw.map((e) => CallHistoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <CallHistoryItem>[];

    return CallHistoryResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
      data: list,
    );
  }
}

// ---------------- SAFE PARSERS ----------------
num? _asNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

int _asInt(dynamic v, {int def = 0}) => _asNum(v)?.toInt() ?? def;

double _asDouble(dynamic v, {double def = 0}) => _asNum(v)?.toDouble() ?? def;

String _asString(dynamic v, {String def = ''}) {
  final s = (v ?? '').toString();
  return s.isEmpty ? def : s;
}

DateTime _asDate(dynamic v) {
  final s = (v ?? '').toString();
  return DateTime.tryParse(s) ?? DateTime.now();
}

// ✅ duration can be int/double/string. You want String in model.
String _asDurationString(dynamic v, {String def = '0'}) {
  if (v == null) return def;
  if (v is String) return v.isEmpty ? def : v;
  if (v is num) return v.toInt().toString();
  final s = v.toString();
  return s.isEmpty ? def : s;
}

// ---------------- ITEM ----------------
class CallHistoryItem {
  final String id;

  /// can be "-1" for missed/failed, but API sends number too -> keep String
  final String callDuration;

  final String callType; // "audio" or "video" (or "message" in your log)

  final String userPhone;
  final String userName;
  final String userMemberID;

  /// ✅ API may send 10 or 10.0 -> safe parse to int
  final int userSpentAmount;

  final String userId;

  /// ✅ API may send 0 or 0.0 -> safe parse to int
  final int staffEarned;

  final String staffId;
  final String staffEmail;
  final String staffPhone;
  final String staffName;
  final String staffMemberID;

  final DateTime createdAt;
  final DateTime updatedAt;

  final int v;

  CallHistoryItem({
    required this.id,
    required this.callDuration,
    required this.callType,
    required this.userPhone,
    required this.userName,
    required this.userMemberID,
    required this.userSpentAmount,
    required this.userId,
    required this.staffEarned,
    required this.staffId,
    required this.staffEmail,
    required this.staffPhone,
    required this.staffName,
    required this.staffMemberID,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: _asString(json['_id']),
      callDuration: _asDurationString(json['callDuration'], def: '0'),
      callType: _asString(json['callType'], def: 'audio'),

      userPhone: _asString(json['userPhone']),
      userName: _asString(json['userName'], def: 'Unknown'),
      userMemberID: _asString(json['userMemberID']),

      userSpentAmount: _asInt(json['userSpentAmount']), // ✅ FIXED
      userId: _asString(json['userId']),

      staffEarned: _asInt(json['staffEarned']), // ✅ FIXED
      staffId: _asString(json['staffId']),
      staffEmail: _asString(json['staffEmail']),
      staffPhone: _asString(json['staffPhone']),
      staffName: _asString(json['staffName'], def: 'Unknown'),
      staffMemberID: _asString(json['staffMemberID']),

      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),

      v: _asInt(json['__v']), // ✅ FIXED
    );
  }

  // Helper to determine status (for UI)
  CallStatus get status {
    if (callDuration == "-1") return CallStatus.missed;
    return CallStatus.completed;
  }
}

// Reuse your existing enum or define here
enum CallStatus { completed, missed, outgoing }
enum CallType { audio, video }


// class CallHistoryResponse {
//   final bool status;
//   final String message;
//   final List<CallHistoryItem>? data;
//
//   CallHistoryResponse({
//     required this.status,
//     required this.message,
//     this.data,
//   });
//
//   factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
//     return CallHistoryResponse(
//       status: json['status'] as bool? ?? false,
//       message: json['message'] as String? ?? '',
//       data: (json['data'] as List<dynamic>?)
//           ?.map((e) => CallHistoryItem.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
// }
//
// class CallHistoryItem {
//   final String id;
//   final String callDuration; // can be "-1" for missed/failed
//   final String callType;     // "audio" or "video"
//   final String userPhone;
//   final String userName;
//   final String userMemberID;
//   final int userSpentAmount;
//   final String userId;
//   final int staffEarned;
//   final String staffId;
//   final String staffEmail;
//   final String staffPhone;
//   final String staffName;
//   final String staffMemberID;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final int v;
//
//   CallHistoryItem({
//     required this.id,
//     required this.callDuration,
//     required this.callType,
//     required this.userPhone,
//     required this.userName,
//     required this.userMemberID,
//     required this.userSpentAmount,
//     required this.userId,
//     required this.staffEarned,
//     required this.staffId,
//     required this.staffEmail,
//     required this.staffPhone,
//     required this.staffName,
//     required this.staffMemberID,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.v,
//   });
//
//   factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
//     return CallHistoryItem(
//       id: json['_id'] as String? ?? '',
//       callDuration: json['callDuration'] as String? ?? '0',
//       callType: json['callType'] as String? ?? 'audio',
//       userPhone: json['userPhone'] as String? ?? '',
//       userName: json['userName'] as String? ?? 'Unknown',
//       userMemberID: json['userMemberID'] as String? ?? '',
//       userSpentAmount: json['userSpentAmount'] as int? ?? 0,
//       userId: json['userId'] as String? ?? '',
//       staffEarned: json['staffEarned'] as int? ?? 0,
//       staffId: json['staffId'] as String? ?? '',
//       staffEmail: json['staffEmail'] as String? ?? '',
//       staffPhone: json['staffPhone'] as String? ?? '',
//       staffName: json['staffName'] as String? ?? 'Unknown',
//       staffMemberID: json['staffMemberID'] as String? ?? '',
//       createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
//       updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
//       v: json['__v'] as int? ?? 0,
//     );
//   }
//
//   // Helper to determine status (for UI)
//   CallStatus get status {
//     if (callDuration == "-1") return CallStatus.missed;
//     return CallStatus.completed; // or outgoing/incoming based on logic
//   }
// }
//
// // Reuse your existing enum or define here
// enum CallStatus { completed, missed, outgoing }
// enum CallType { audio, video }