// lib/BondingScreens/HomeScreen/Model/UserDataModel.dart

class UserDetailsResponse {
  final bool status;
  final String message;
  final UserProfile? data;

  UserDetailsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory UserDetailsResponse.fromJson(Map<String, dynamic> json) {
    return UserDetailsResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? UserProfile.fromJson(json['data']) : null,
    );
  }
}

class UserProfile {
  final String id;
  final String phone;
  final bool isVerified;
  final String memberID;
  final bool isOAuth;
  final bool isLogin;
  final String? ip;
  final int totalPurchaseAmount;
  final int totalProductReferred;
  final String role;
  final String affiliateStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? image;
  final String? dob;
  final String? bio;
  final String? gender;
  final String? name;
  final List<InterestItem>? areaOfInterest;
  final String? language;
  final int? coinBalance;
  final String? formStatus;

  UserProfile({
    required this.id,
    required this.phone,
    required this.isVerified,
    required this.memberID,
    required this.isOAuth,
    required this.isLogin,
    this.ip,
    required this.totalPurchaseAmount,
    required this.totalProductReferred,
    required this.role,
    required this.affiliateStatus,
    required this.createdAt,
    required this.updatedAt,
    this.image,
    this.dob,
    this.bio,
    this.gender,
    this.name,
    this.areaOfInterest,
    this.language,
    this.coinBalance,
    this.formStatus,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    print("Raw keys in fromJson: ${json.keys.toList()}");
    print("formStatus raw: ${json['formStatus']}");

    return UserProfile(
      id: json['_id'] ?? '',
      phone: json['phone'] ?? '',
      isVerified: json['isVerified'] == true,
      memberID: json['memberID'] ?? '',
      isOAuth: json['isOAuth'] == true,
      isLogin: json['isLogin'] == true,
      ip: json['ip']?.toString(),
      totalPurchaseAmount: json['totalPurchaseAmount'] ?? 0,
      totalProductReferred: json['totalProductReferred'] ?? 0,
      role: json['role'] ?? '',
      affiliateStatus: json['affiliateStatus'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      image: json['image']?.toString(),
      dob: json['DOB']?.toString(),
      bio: json['bio']?.toString(),
      gender: json['gender']?.toString(),
      name: json['name']?.toString(),
      areaOfInterest: (json['areaOfInterest'] as List<dynamic>?)
          ?.map((e) => InterestItem.fromJson(e))
          .toList(),
      language: json['Language']?.toString(),
      coinBalance: json['coinBalance'] as int?,
      formStatus: json['formStatus']?.toString(),
    );
  }

  // ─── ADD THIS copyWith METHOD ───────────────────────────────────────────
  UserProfile copyWith({
    String? id,
    String? phone,
    bool? isVerified,
    String? memberID,
    bool? isOAuth,
    bool? isLogin,
    String? ip,
    int? totalPurchaseAmount,
    int? totalProductReferred,
    String? role,
    String? affiliateStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? image,
    String? dob,
    String? bio,
    String? gender,
    String? name,
    List<InterestItem>? areaOfInterest,
    String? language,
    int? coinBalance,
    String? formStatus,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      memberID: memberID ?? this.memberID,
      isOAuth: isOAuth ?? this.isOAuth,
      isLogin: isLogin ?? this.isLogin,
      ip: ip ?? this.ip,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      totalProductReferred: totalProductReferred ?? this.totalProductReferred,
      role: role ?? this.role,
      affiliateStatus: affiliateStatus ?? this.affiliateStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      image: image ?? this.image,
      dob: dob ?? this.dob,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      name: name ?? this.name,
      areaOfInterest: areaOfInterest ?? this.areaOfInterest,
      language: language ?? this.language,
      coinBalance: coinBalance ?? this.coinBalance,
      formStatus: formStatus ?? this.formStatus,
    );
  }
}

class InterestItem {
  final String title;

  InterestItem({required this.title});

  factory InterestItem.fromJson(Map<String, dynamic> json) => InterestItem(title: json['title'] ?? '');
}