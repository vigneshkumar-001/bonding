// lib/repositories/wallet_repository.dart

import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/PrivacyPolicy/Model/privacy_policy_response.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/Model/support_create_ticket_response.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/Model/ticket_message_history_response.dart';
import 'package:bonding_app/BondingScreens/Transactions/Model/TransactionHistoryModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/PaymentModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:bonding_app/BondingScreens/WalletScreen/razorPayFlow/Model/confirmPaymentModel.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/callStatusModel.dart';
import 'package:bonding_app/BondingScreens/SupportScreen/Model/support_list_response.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/AddBankDetailsModel.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/BankDetailModel.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/WithdrawHistoryModel.dart';
import 'package:bonding_app/StaffScreenScreens/WithdrawScreen/Model/WithdrawRequestModel.dart';
import 'package:flutter/foundation.dart';

import '../../SupportScreen/Model/support_ticket_add_message_response.dart';

class SettingsRepository {
  final NetworkApiService _apiService = NetworkApiService();

  SettingsRepository();

  Future<PrivacyPolicyResponse> getPrivacyPolicy() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().privacyPolicy, // "staff/getAllBankDetails"
      );

      if (kDebugMode) {
        print("Get All privacyPolicy Details Response: $response");
      }

      final resp = PrivacyPolicyResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch bank details");
      }
    } catch (e) {
      debugPrint("privacyPolicy  error: $e");
      throw Exception("Failed to fetch privacyPolicy details: $e");
    }
  }

  Future<SupportTicketCreateResponse> postCreateTicket({
    required String title,
    required bool isStaff,
    required String description,
    required String message,
    List<String> media = const [],
  }) async {
    try {
      final endpoint = isStaff
          ? ApiEndPoints().staffSupportTicketCreate
          : ApiEndPoints().userSupportTicketCreate;
      final body = {
        "title": title,
        "description": description,
        "message": message,
        "media": media,
      };

      final response = await _apiService.postResponseV2(
        endpoint,
        body: body, // ✅ IMPORTANT: your postResponseV2 must accept body
      );

      if (kDebugMode) {
        print("SupportTicketCreateResponse: $response");
      }

      final resp = SupportTicketCreateResponse.fromJson(response);
      return resp;
    } catch (e) {
      debugPrint("SupportTicketCreateResponse error: $e");
      throw Exception("Failed to create ticket: $e");
    }
  }

  Future<TicketMessageHistoryResponse> getTicketHistory(
    String ticketId, {
    required bool isStaff,
  }) async {
    try {
      // "${ApiEndPoints().userSupportTicketHistory}/$ticketId",
      final endpoint = isStaff
          ? ApiEndPoints().staffSupportTicketHistory
          : ApiEndPoints().userSupportTicketHistory;
      final response = await _apiService.getResponseV2("$endpoint/$ticketId");
      if (kDebugMode) {
        print("getTicketHistory Response: $response");
        AppLogger.log.i("getTicketHistory Response: $response");
      }
      final resp = TicketMessageHistoryResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      debugPrint("fetch ticket history error: $e");
      AppLogger.log.e("fetch ticket history error: $e");
      throw Exception("Failed to fetch ticket history: $e");
    }
  }

  Future<SupportTicketAddMessageResponse> postAddTicketMessage({
    required String ticketId,
    required bool isStaff,
    required String message,
    List<String> media = const [],
  }) async {
    try {
      // "${ApiEndPoints().userSupportTicketAddMessage}/$ticketId",
      final endpoint = isStaff
          ? ApiEndPoints().staffSupportTicketAddMessage
          : ApiEndPoints().userSupportTicketAddMessage;
      final body = {"message": message, "media": media};

      final response = await _apiService.postResponseV2(
        "$endpoint/$ticketId",
        body: body,
      );
      if (kDebugMode) {
        print("Support Ticket Add Response: $response");
      }
      final resp = SupportTicketAddMessageResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      debugPrint("Failed to send message: $e");
      AppLogger.log.e("Failed to send message: $e");
      throw Exception("Failed to send message: $e");
    }
  }

  Future<SupportTicketListResponse> getSupportTickets({
    int page = 1,
    int limit = 20,
    required bool isStaff,
  }) async {
    try {
      final endpoint = isStaff
          ? ApiEndPoints().supportTicketList
          : ApiEndPoints().userSupportTicketList;

      final response = await _apiService.getResponseV2(
        "$endpoint?page=$page&limit=$limit",
      );

      if (kDebugMode) {
        print("Support Ticket List Response: $response");
      }

      final resp = SupportTicketListResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      debugPrint("getSupportTickets error: $e");
      throw Exception("Failed to fetch support tickets: $e");
    }
  }
}
