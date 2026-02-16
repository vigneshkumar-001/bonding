// lib/models/bio_profile_response.dart  (or update_profile_bio_response.dart)
class BioProfileResponse {
  final bool status;
  final String message;
  final UserBioData? data;

  BioProfileResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory BioProfileResponse.fromJson(Map<String, dynamic> json) {
    return BioProfileResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? UserBioData.fromJson(json['data'])
          : null,
    );
  }

  // 🔥 FIXED
  bool get isSuccess => status;
}

class UserBioData {
  final String id;
  final String? email;
  final String phone;
  final String memberID;
  final String? name;
  final String? gender;
  final String? dob;
  final String? bio;
  final String role;
  final bool isLogin;
  final bool isOAuth;
  final int coinBalance;
  final int totalCoinBalance;
  final int totalPurchaseAmount;
  final String? formStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserBioData({
    required this.id,
    this.email,
    required this.phone,
    required this.memberID,
    this.name,
    this.gender,
    this.dob,
    this.bio,
    required this.role,
    required this.isLogin,
    required this.isOAuth,
    required this.coinBalance,
    required this.totalCoinBalance,
    required this.totalPurchaseAmount,
    this.formStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory UserBioData.fromJson(Map<String, dynamic> json) {
    return UserBioData(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      memberID: json['memberID']?.toString() ?? '',
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['DOB']?.toString(),
      bio: json['bio']?.toString(),
      role: json['role']?.toString() ?? '',
      isLogin: json['isLogin'] == true,
      isOAuth: json['isOAuth'] == true,
      coinBalance: json['coinBalance'] is int
          ? json['coinBalance']
          : int.tryParse(json['coinBalance']?.toString() ?? '0') ?? 0,
      totalCoinBalance: json['totalCoinBalance'] is int
          ? json['totalCoinBalance']
          : int.tryParse(json['totalCoinBalance']?.toString() ?? '0') ?? 0,
      totalPurchaseAmount: json['totalPurchaseAmount'] is int
          ? json['totalPurchaseAmount']
          : int.tryParse(json['totalPurchaseAmount']?.toString() ?? '0') ?? 0,
      formStatus: json['formStatus']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

/*
class UserBioData {
  final String id;
  final String phone;
  final bool isVerified;
  final String memberID;
  final String? name;
  final String? gender;
  final String? dob;           // stored as string from your backend
  final String? bio;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBioData({
    required this.id,
    required this.phone,
    required this.isVerified,
    required this.memberID,
    this.name,
    this.gender,
    this.dob,
    this.bio,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBioData.fromJson(Map<String, dynamic> json) {
    return UserBioData(
      id: json['_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      memberID: json['memberID']?.toString() ?? '',
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['DOB']?.toString(),
      bio: json['bio']?.toString(),
      image: json['image']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}*/
