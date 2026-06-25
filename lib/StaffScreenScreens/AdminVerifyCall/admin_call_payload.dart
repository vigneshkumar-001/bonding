// lib/StaffScreenScreens/AdminVerifyCall/admin_call_payload.dart
//
// Payload for the Admin -> Staff verification video call (ZEGOCLOUD).
//
// The SAME payload arrives via two delivery paths:
//   A) Socket event `incoming_admin_call`  -> values are typed (int appID, etc.)
//   B) FCM data message (type "admin_verify_call") -> ALL values are Strings.
//
// `AdminCallPayload.fromMap` is intentionally tolerant of both shapes.

import 'dart:convert';

const String kAdminVerifyCallType = 'admin_verify_call';
const String kIncomingAdminCallEvent = 'incoming_admin_call';

class AdminCallPayload {
  final String type; // "admin_verify_call"
  final String callType; // "video"
  final String roomID; // "verify_<staffId>_<stamp>" -> ZEGO callID
  final int appID; // numeric ZEGO AppID
  final String token; // server ZEGO Token04 -> use as-is
  final String zegoUserID; // "staff_<staffId>"
  final String zegoUserName; // staff display name
  final String callerName; // admin name
  final String staffId; // mongo staff id

  const AdminCallPayload({
    required this.type,
    required this.callType,
    required this.roomID,
    required this.appID,
    required this.token,
    required this.zegoUserID,
    required this.zegoUserName,
    required this.callerName,
    required this.staffId,
  });

  /// Whether we have the minimum required fields to actually join a room.
  bool get isValid =>
      roomID.isNotEmpty &&
      token.isNotEmpty &&
      appID != 0 &&
      zegoUserID.isNotEmpty;

  bool get isVerifyCall => type == kAdminVerifyCallType;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static String _asString(dynamic v) => (v ?? '').toString().trim();

  /// Tolerant parser. Accepts socket (typed) and FCM (all-String) maps.
  factory AdminCallPayload.fromMap(Map<dynamic, dynamic> data) {
    return AdminCallPayload(
      type: _asString(data['type']),
      callType: _asString(data['callType']).isEmpty
          ? 'video'
          : _asString(data['callType']),
      roomID: _asString(data['roomID']),
      appID: _asInt(data['appID']),
      token: _asString(data['token']),
      zegoUserID: _asString(data['zegoUserID']),
      zegoUserName: _asString(data['zegoUserName']),
      callerName: _asString(data['callerName']),
      staffId: _asString(data['staffId']),
    );
  }

  /// String map for round-tripping through a local-notification payload.
  Map<String, String> toStringMap() => {
        'type': type,
        'callType': callType,
        'roomID': roomID,
        'appID': appID.toString(),
        'token': token,
        'zegoUserID': zegoUserID,
        'zegoUserName': zegoUserName,
        'callerName': callerName,
        'staffId': staffId,
      };

  String toJsonString() => jsonEncode(toStringMap());

  factory AdminCallPayload.fromJsonString(String s) {
    final decoded = jsonDecode(s);
    if (decoded is Map) return AdminCallPayload.fromMap(decoded);
    return const AdminCallPayload(
      type: '',
      callType: 'video',
      roomID: '',
      appID: 0,
      token: '',
      zegoUserID: '',
      zegoUserName: '',
      callerName: '',
      staffId: '',
    );
  }

  /// A non-empty display name for the staff inside the ZEGO room.
  String get safeUserName =>
      zegoUserName.isNotEmpty ? zegoUserName : (staffId.isNotEmpty ? 'Staff_$staffId' : 'Staff');

  @override
  String toString() =>
      'AdminCallPayload(type=$type, callType=$callType, roomID=$roomID, '
      'appID=$appID, zegoUserID=$zegoUserID, callerName=$callerName, '
      'tokenLen=${token.length})';
}
