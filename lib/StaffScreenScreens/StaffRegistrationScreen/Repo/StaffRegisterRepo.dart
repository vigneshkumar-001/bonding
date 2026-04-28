// lib/repositories/staff_repository.dart

import 'dart:io';

import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/Model/ProfileModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/Model/InterestModel.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/StaffScreenScreens/ProfileVerficationScreen/Model/ProfileIdModel.dart';
import 'package:bonding_app/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/CallGraphModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/callStatusModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/Model/StaffRegisterModel.dart';
import 'package:flutter/foundation.dart';

class StaffRepository {
  final NetworkApiService _apiService;

  StaffRepository(this._apiService);

  Future<StaffRegisterResponse> registerStaff({
    required String phone,
    required String name,
    required String email,
    required String city,
    required String dob,
  }) async {
    try {
      final body = {
        "phone": phone,
        "name": name,
        "email": email,
        "city": city,
        "dob": dob,
      };

      final response = await _apiService.postResponseV2(
        ApiEndPoints().staffRegister, // → "/api/v1/auth/user/staffdata"
        body: body,
      );

      if (kDebugMode) {
        debugPrint("Register response: $response");
      }

      final staffResp = StaffRegisterResponse.fromJson(response);

      if (staffResp.isSuccess) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository registerStaff error: $e");
    }
  }

  // lib/repositories/staff_repository.dart

  Future<StaffIdVerifyResponse> verifyStaffId({
    required String idType,
    required String idNumber,
  }) async {
    try {
      final body = {"IDtype": idType, "IDnumber": idNumber};

      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffIdVerify, // → "/api/v1/auth/user/staffIdVerify"
        body: body,
      );

      if (kDebugMode) {
        debugPrint("ID verify response: $response");
      }

      final verifyResp = StaffIdVerifyResponse.fromJson(response);

      if (verifyResp.isSuccess) {
        return verifyResp;
      } else {
        throw Exception(verifyResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository verifyStaffId error: $e");
    }
  }

  Future<UpdateProfileResponse> updateProfileImage(File imageFile) async {
    try {
      // Optional: get token
      final token = await AuthService.getToken();

      final response = await _apiService.uploadImageMultipart(
        endpoint: ApiEndPoints().updateStaffProfile,
        imageFile: imageFile,
        fieldName: 'image',
        token: token,
        // additionalFields: {'someKey': 'value'}, // if needed later
      );

      if (kDebugMode) {
        debugPrint("Profile image upload response: $response");
      }

      final updateResp = UpdateProfileResponse.fromJson(response);

      if (updateResp.isSuccess) {
        return updateResp;
      } else {
        throw Exception(updateResp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateProfileImage error: $e");
    }
  }

  Future<AreaOfInterestResponse> updateStaffAreaOfInterest({
    required List<String> interests,
  }) async {
    try {
      final body = {
        "areaOfInterest": interests.map((title) => {"title": title}).toList(),
      };

      final response = await _apiService.postResponseV3(
        ApiEndPoints().updateStaffAreaOfInterest,
        body: body,
      );

      if (kDebugMode) {
        debugPrint("Interests update response: $response");
      }

      final resp = AreaOfInterestResponse.fromJson(response);
      if (kDebugMode) debugPrint("Interests update parsed: $resp");

      if (resp.isSuccess) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateAreaOfInterest error: $e");
    }
  }

  Future<StaffDetailsResponse> getStaffDetails() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getStaffDetails, // "/api/v1/auth/user/getstaffDetails"
        // If it requires auth token, add headers here
        // headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        debugPrint("Details response: $response");
        AppLogger.log.i("Details response: $response");
      }

      final staffResp = StaffDetailsResponse.fromJson(response);

      if (staffResp.status) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository getStaffDetails error: $e");
    }
  }

  // lib/repositories/staff_repository.dart  (or auth_repository.dart)

  Future<StaffSingleDataResponse> getStaffSingleData() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints()
            .getStaffSingleData, // "/api/v1/auth/user/getstaffSingleData"
        // Add auth header if required
        // headers: {'Authorization': 'Bearer ${await AuthService.getToken()}'},
      );

      if (kDebugMode) {
        debugPrint("Single data response: $response");
        AppLogger.log.i("Single data response: $response");
      }
      final staffResp = StaffSingleDataResponse.fromJson(response);

      if (staffResp.status && staffResp.data != null) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository getStaffSingleData error: $e");
    }
  }

  Future<CallHistoryResponse> getStaffCallHistory() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffCallHistory, // ← your GET endpoint
      );

      if (kDebugMode) {
        debugPrint("Call history response: $response");
        AppLogger.log.i("Call history response: $response");
      }

      final resp = CallHistoryResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch call history");
      }
    } catch (e,st) {
      AppLogger.log.e('$e,$st');
      throw Exception("CallRepository getStaffCallHistory error: $e");
    }
  }

  Future<StaffCallStatsResponse> getStaffCallStats() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffCallStats, // "staff/getStaffCallStats"
      );

      if (kDebugMode) {
        debugPrint("Call stats response: $response");
      }

      final resp = StaffCallStatsResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch call stats");
      }
    } catch (e,st) {
      if (kDebugMode) debugPrint("getStaffCallStats error: $e");
      AppLogger.log.e('getStaffCallStats error:\n$e,$st');

      throw Exception("Failed to fetch call stats: $e");
    }
  }

  Future<StaffWeeklyCallGraphResponse> getWeeklyCallGraph() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffWeeklyCallGraph, // "staff/getWeeklyCallGraph"
      );

      if (kDebugMode) {
        debugPrint("Weekly call graph response: $response");
      }

      final resp = StaffWeeklyCallGraphResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch weekly call graph");
      }
    } catch (e) {
      debugPrint("Repository getWeeklyCallGraph error: $e");
      throw Exception("Failed to fetch weekly call graph: $e");
    }
  }
}
