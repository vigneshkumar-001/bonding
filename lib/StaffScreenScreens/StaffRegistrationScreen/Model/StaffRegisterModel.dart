// lib/models/staff_register_response.dart

class StaffRegisterResponse {
  final bool status;
  final String message;
  final String? otp;
  final DateTime? otpExpiresTime;

  StaffRegisterResponse({
    required this.status,
    required this.message,
    this.otp,
    this.otpExpiresTime,
  });

  factory StaffRegisterResponse.fromJson(Map<String, dynamic> json) {
    return StaffRegisterResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Registration failed',
      otp: json['otp']?.toString(),
      otpExpiresTime: json['otpExpiresTime'] != null
          ? DateTime.tryParse(json['otpExpiresTime'])
          : null,
    );
  }

  // Some endpoints return only `{status, message}` (no OTP). Treat `status=true` as success.
  bool get isSuccess => status;

  bool get hasOtp => otp != null && otp!.isNotEmpty;
}
