// lib/models/staff_details_model.dart

class StaffDetailsResponse {
  final bool status;
  final String message;

  /// Top-level call rates (from "callRates")
  final CallRates? callRates;

  /// Staff list (from "data")
  final List<StaffDataProfile> data;

  const StaffDetailsResponse({
    required this.status,
    required this.message,
    required this.data,
    this.callRates,
  });

  factory StaffDetailsResponse.fromJson(Map<String, dynamic> json) {
    return StaffDetailsResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Failed to fetch staff details',
      callRates: json['callRates'] is Map<String, dynamic>
          ? CallRates.fromJson(json['callRates'] as Map<String, dynamic>)
          : null,
      data:
          (json['data'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(StaffDataProfile.fromJson)
              .toList() ??
          const <StaffDataProfile>[],
    );
  }
}

class CallRates {
  final int audioCallAmount;
  final int videoCallAmount;
  final String currency;

  const CallRates({
    required this.audioCallAmount,
    required this.videoCallAmount,
    required this.currency,
  });

  factory CallRates.fromJson(Map<String, dynamic> json) {
    return CallRates(
      audioCallAmount: (json['audio_call_amount'] as num?)?.toInt() ?? 0,
      videoCallAmount: (json['video_call_amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}

class StaffDataProfile {
  final String id;

  final String email;
  final String phone;
  final String name;

  final String memberID;
  final String? gender;
  final String role;
  final String? dob;

  /// money fields in your payload are sometimes decimals, so keep as `num`
  final num totalEarnings;
  final num pendingBalance;
  final num balance;
  final num coinAmount;
  final num coin;
  final num staffEarned;

  final bool isLogin;
  final String isApproved;

  final List<InterestItem> areaOfInterest;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// KYC-ish
  final String? idNumber;
  final String? idType;
  final String? formStatus;
  final String? image;
  final String? bio;

  /// Presence
  final bool isOnline;
  final DateTime? lastSeen;
  final String? socketId;

  /// API-controlled permission: whether user can start calls with this staff.
  /// If backend doesn't send it, stays null and client may fallback to local rules.
  final bool? callEnabled;

  /// Rates (present on each staff item)
  final int audioCallAmount;
  final int videoCallAmount;
  final int audioCallRatePerMinute;
  final int videoCallRatePerMinute;
  final String currency;

  const StaffDataProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.name,
    required this.memberID,
    required this.role,
    required this.isLogin,
    required this.isApproved,
    required this.areaOfInterest,
    required this.isOnline,
    this.callEnabled,
    required this.audioCallAmount,
    required this.videoCallAmount,
    required this.audioCallRatePerMinute,
    required this.videoCallRatePerMinute,
    required this.currency,
    this.gender,
    this.dob,
    this.totalEarnings = 0,
    this.pendingBalance = 0,
    this.balance = 0,
    this.coinAmount = 0,
    this.coin = 0,
    this.staffEarned = 0,
    this.createdAt,
    this.updatedAt,
    this.idNumber,
    this.idType,
    this.formStatus,
    this.image,
    this.bio,
    this.lastSeen,
    this.socketId,
  });

  factory StaffDataProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return StaffDataProfile(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      memberID: json['memberID']?.toString() ?? '',
      gender: json['gender']?.toString(),
      role: json['role']?.toString() ?? 'Staff',
      dob: json['dob']?.toString(),

      totalEarnings: (json['totalEarnings'] as num?) ?? 0,
      pendingBalance: (json['pendingBalance'] as num?) ?? 0,
      balance: (json['balance'] as num?) ?? 0,
      coinAmount: (json['coinAmount'] as num?) ?? 0,
      coin: (json['coin'] as num?) ?? 0,
      staffEarned: (json['staffEarned'] as num?) ?? 0,

      isLogin: json['isLogin'] == true,
      isApproved: json['isApproved']?.toString() ?? '0',

      areaOfInterest:
          (json['areaOfInterest'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(InterestItem.fromJson)
              .toList() ??
          const <InterestItem>[],

      createdAt: parseDt(json['createdAt']),
      updatedAt: parseDt(json['updatedAt']),

      idNumber: json['IDnumber']?.toString(),
      idType: json['IDtype']?.toString(),
      formStatus: json['formStatus']?.toString(),
      image: json['image']?.toString(),
      bio: json['bio']?.toString(),

      isOnline: json['isOnline'] == true,
      lastSeen: parseDt(json['lastSeen']),
      socketId: json['socketId']?.toString(),
      callEnabled: _parseOptionalBool(json['callEnabled'] ?? json['canCall']),

      audioCallAmount: (json['audio_call_amount'] as num?)?.toInt() ?? 0,
      videoCallAmount: (json['video_call_amount'] as num?)?.toInt() ?? 0,
      audioCallRatePerMinute:
          (json['audioCallRatePerMinute'] as num?)?.toInt() ?? 0,
      videoCallRatePerMinute:
          (json['videoCallRatePerMinute'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  static bool? _parseOptionalBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    if (s == "true" || s == "1" || s == "yes") return true;
    if (s == "false" || s == "0" || s == "no") return false;
    return null;
  }

  /// Safe presence update
  StaffDataProfile copyWith({
    bool? isOnline,
    DateTime? lastSeen,
    String? socketId,
    bool? callEnabled,
  }) {
    return StaffDataProfile(
      id: id,
      email: email,
      phone: phone,
      name: name,
      memberID: memberID,
      gender: gender,
      role: role,
      dob: dob,
      totalEarnings: totalEarnings,
      pendingBalance: pendingBalance,
      balance: balance,
      coinAmount: coinAmount,
      coin: coin,
      staffEarned: staffEarned,
      isLogin: isLogin,
      isApproved: isApproved,
      areaOfInterest: areaOfInterest,
      createdAt: createdAt,
      updatedAt: updatedAt,
      idNumber: idNumber,
      idType: idType,
      formStatus: formStatus,
      image: image,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      socketId: socketId ?? this.socketId,
      callEnabled: callEnabled ?? this.callEnabled,
      audioCallAmount: audioCallAmount,
      videoCallAmount: videoCallAmount,
      audioCallRatePerMinute: audioCallRatePerMinute,
      videoCallRatePerMinute: videoCallRatePerMinute,
      currency: currency,
    );
  }

  /// Safe age calculator for "dd/MM/yyyy"
  int? get age {
    final v = dob;
    if (v == null || v.trim().isEmpty) return null;

    final parts = v.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    final birth = DateTime(year, month, day);
    final now = DateTime.now();

    var a = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      a--;
    }
    return a >= 0 ? a : null;
  }
}

class InterestItem {
  final String title;

  const InterestItem({required this.title});

  factory InterestItem.fromJson(Map<String, dynamic> json) {
    return InterestItem(title: json['title']?.toString() ?? '');
  }
}

// // lib/models/staff_details_model.dart
//
// class StaffDetailsResponse {
//   final bool status;
//   final String message;
//   final List<StaffDataProfile>? data;
//
//   StaffDetailsResponse({
//     required this.status,
//     required this.message,
//     this.data,
//   });
//
//   factory StaffDetailsResponse.fromJson(Map<String, dynamic> json) {
//     return StaffDetailsResponse(
//       status: json['status'] == true,
//       message: json['message']?.toString() ?? 'Failed to fetch staff details',
//       data: (json['data'] as List<dynamic>?)
//           ?.map((e) =>
//           StaffDataProfile.fromJson(e as Map<String, dynamic>))
//           .toList(),
//     );
//   }
// }
//
// class StaffDataProfile {
//   final String id;
//   final String email;
//   final String phone;
//   final String name;
//   final String? otpExpiresAt;
//   final String memberID;
//   final String? otp;
//   final String? gender;
//   final String role;
//   final int balance;
//   final bool isLogin;
//   final List<InterestItem> areaOfInterest;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final String? idNumber;
//   final String? idType;
//   final String? image;
//   final String? dob;
//
//   /// 🔥 Presence fields
//   final bool isOnline;
//   final DateTime? lastSeen;
//   final String? socketId;
//
//   StaffDataProfile({
//     required this.id,
//     required this.email,
//     required this.phone,
//     required this.name,
//     this.otpExpiresAt,
//     required this.memberID,
//     this.otp,
//     this.gender,
//     required this.role,
//     required this.balance,
//     required this.isLogin,
//     required this.areaOfInterest,
//     required this.createdAt,
//     required this.updatedAt,
//     this.idNumber,
//     this.idType,
//     this.image,
//     this.dob,
//     required this.isOnline,
//     this.lastSeen,
//     this.socketId,
//   });
//
//   /// ─────────────────────────────────────────
//   /// JSON Parsing
//   /// ─────────────────────────────────────────
//
//   factory StaffDataProfile.fromJson(Map<String, dynamic> json) {
//     return StaffDataProfile(
//       id: json['_id']?.toString() ?? '',
//       email: json['email']?.toString() ?? '',
//       phone: json['phone']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//       otpExpiresAt: json['otpExpiresAt']?.toString(),
//       memberID: json['memberID']?.toString() ?? '',
//       otp: json['otp']?.toString(),
//       gender: json['gender']?.toString(),
//       role: json['role']?.toString() ?? 'User',
//       balance: (json['balance'] as num?)?.toInt() ?? 0,
//       isLogin: json['isLogin'] == true,
//
//       areaOfInterest: (json['areaOfInterest'] as List<dynamic>?)
//           ?.map((e) =>
//           InterestItem.fromJson(e as Map<String, dynamic>))
//           .toList() ??
//           [],
//
//       createdAt:
//       DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
//           DateTime.now(),
//
//       updatedAt:
//       DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
//           DateTime.now(),
//
//       idNumber: json['IDnumber']?.toString(),
//       idType: json['IDtype']?.toString(),
//       image: json['image']?.toString(),
//       dob: json['dob']?.toString(),
//
//       /// presence
//       isOnline: json['isOnline'] == true,
//       lastSeen: json['lastSeen'] != null
//           ? DateTime.tryParse(json['lastSeen'].toString())
//           : null,
//       socketId: json['socketId']?.toString(),
//     );
//   }
//
//   /// ─────────────────────────────────────────
//   /// copyWith → fixes your error
//   /// ─────────────────────────────────────────
//
//   StaffDataProfile copyWith({
//     bool? isOnline,
//     DateTime? lastSeen,
//     String? socketId,
//   }) {
//     return StaffDataProfile(
//       id: id,
//       email: email,
//       phone: phone,
//       name: name,
//       otpExpiresAt: otpExpiresAt,
//       memberID: memberID,
//       otp: otp,
//       gender: gender,
//       role: role,
//       balance: balance,
//       isLogin: isLogin,
//       areaOfInterest: areaOfInterest,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//       idNumber: idNumber,
//       idType: idType,
//       image: image,
//       dob: dob,
//       isOnline: isOnline ?? this.isOnline,
//       lastSeen: lastSeen ?? this.lastSeen,
//       socketId: socketId ?? this.socketId,
//     );
//   }
//
//   /// ─────────────────────────────────────────
//   /// Age Calculator
//   /// ─────────────────────────────────────────
//
//   int? get age {
//     if (dob == null || dob!.isEmpty) return null;
//
//     try {
//       final parts = dob!.split('/');
//       if (parts.length != 3) return null;
//
//       final day = int.tryParse(parts[0]);
//       final month = int.tryParse(parts[1]);
//       final year = int.tryParse(parts[2]);
//
//       if (day == null || month == null || year == null) return null;
//
//       final birthDate = DateTime(year, month, day);
//       final now = DateTime.now();
//
//       int age = now.year - birthDate.year;
//
//       if (now.month < birthDate.month ||
//           (now.month == birthDate.month &&
//               now.day < birthDate.day)) {
//         age--;
//       }
//
//       return age >= 0 ? age : null;
//     } catch (_) {
//       return null;
//     }
//   }
// }
//
// class InterestItem {
//   final String title;
//
//   InterestItem({required this.title});
//
//   factory InterestItem.fromJson(Map<String, dynamic> json) {
//     return InterestItem(
//       title: json['title']?.toString() ?? '',
//     );
//   }
// }
