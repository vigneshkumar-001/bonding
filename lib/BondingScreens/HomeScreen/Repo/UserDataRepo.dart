// lib/repositories/user_repository.dart

import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UpdateBalanceModel.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final NetworkApiService _apiService;

  UserRepository(this._apiService);

  Future<UserDetailsResponse> getUserDetails() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getUserDetails,
      );

      if (kDebugMode) {
        print("Get User Details Response: $response");
      }

      final userResp = UserDetailsResponse.fromJson(response);

      if (userResp.status && userResp.data != null) {
        return userResp;
      } else {
        throw Exception(
          userResp.message.isNotEmpty ? userResp.message : "Failed to fetch user details",
        );
      }
    } catch (e) {
      throw Exception("UserRepository getUserDetails error: $e");
    }
  }

  Future<UserDetailsResponse> getUserCallHistory() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().userCallHistory,
      );

      if (kDebugMode) {
        print("Get User Details Response: $response");
      }

      final userResp = UserDetailsResponse.fromJson(response);

      if (userResp.status && userResp.data != null) {
        return userResp;
      } else {
        throw Exception(
          userResp.message.isNotEmpty ? userResp.message : "Failed to fetch user details",
        );
      }
    } catch (e) {
      throw Exception("UserRepository getUserDetails error: $e");
    }
  }


  Future<UpdateBalanceResponse> updateCoinBalance({
    required int newCoinBalance,
    required String staffId,
    required dynamic staffAmount,
    required String callDuration,
    required String callType
  }) async
  {
    try {
      final body = {
        "coinBalance": newCoinBalance,
        "staffId":staffId,
        "staffEarned":staffAmount,
        "callDuration":callDuration,
        "callType":callType
      };
      print("body :: $body");

      final response = await _apiService.postResponseV3(
        ApiEndPoints().userBalanceUpdate, // ← your endpoint path
        body: body,
      );

      if (kDebugMode) {
        print("Update Coin Balance Response: $response");
      }

      final resp = UpdateBalanceResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      throw Exception("UserRepository updateCoinBalance error: $e");
    }
  }
// You can add more user-related methods later, e.g.
// Future updateProfile(...)
// Future getWalletBalance(...)
}