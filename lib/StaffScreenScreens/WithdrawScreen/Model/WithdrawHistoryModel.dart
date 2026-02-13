// lib/models/staff_withdraw_history_response.dart

import 'dart:ui';

import 'package:flutter/material.dart';

class StaffWithdrawHistoryResponse {
  final bool status;
  final String message;
  final List<StaffWithdrawHistoryItem>? data;

  StaffWithdrawHistoryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffWithdrawHistoryResponse.fromJson(Map<String, dynamic> json) {
    return StaffWithdrawHistoryResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => StaffWithdrawHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StaffWithdrawHistoryItem {
  final String id;
  final String userId;
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifsc;
  final String bankHolderName;
  final String bankNamee;
  final String? upi;
  final String? confirmUpi;
  final String email;
  final String phone;
  final String image;
  final String name;
  final String otpExpiresAt;
  final String memberID;
  final int amount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  StaffWithdrawHistoryItem({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.confirmAccountNumber,
    required this.ifsc,
    required this.bankHolderName,
    required this.bankNamee,
    this.upi,
    this.confirmUpi,
    required this.email,
    required this.phone,
    required this.image,
    required this.name,
    required this.otpExpiresAt,
    required this.memberID,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory StaffWithdrawHistoryItem.fromJson(Map<String, dynamic> json) {
    return StaffWithdrawHistoryItem(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      confirmAccountNumber: json['confirmAccountNumber'] as String? ?? '',
      ifsc: json['IFSC'] as String? ?? '',
      bankHolderName: json['bankHolderName'] as String? ?? '',
      bankNamee: json['bankNamee'] as String? ?? '',
      upi: json['UPI'] as String?,
      confirmUpi: json['confirmUPI'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      image: json['image'] as String? ?? '',
      name: json['name'] as String? ?? '',
      otpExpiresAt: json['otpExpiresAt'] as String? ?? '',
      memberID: json['memberID'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      v: json['__v'] as int? ?? 0,
    );
  }

  // Helper for UI
  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusText => status.toUpperCase();
}