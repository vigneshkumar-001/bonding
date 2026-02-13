// lib/repositories/auth_repository.dart
import 'dart:io';

import 'package:bonding_app/APIService/Remote/network/ApiEndPoints.dart';
import 'package:bonding_app/APIService/Remote/network/NetworkApiService.dart';
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/Model/ProfileModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/IdentityScreen/Model/IdentifyModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestLanguage/Model/LanguageModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/Model/InterestModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/Model/LoginModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/Model/VerifyOtpModel.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';


class AuthRepository {
  final NetworkApiService _apiService = NetworkApiService();




  Future<SignupResponse> sendOtp(String phoneNumber) async {
    try {
      final body = {
        "phone": phoneNumber,     // adjust key if backend expects "mobile", "number", etc.
      };

      final response = await _apiService.postResponseV2(
        ApiEndPoints().login,    // → "/api/v1/auth/user/signup"
        body: body,
      );

      if (kDebugMode) {
        print("Send OTP Response: $response");
      }

      final signupResp = SignupResponse.fromJson(response);

      if (signupResp.status == true) {
        return signupResp;
      } else {
        throw Exception(signupResp.message.isNotEmpty
            ? signupResp.message
            : "Failed to send OTP");
      }
    } catch (e) {
      throw Exception("AuthRepository sendOtp error: $e");
    }
  }
  Future<VerifyOtpResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async

  {

    try {
      final body = {
        "user": phone,     // backend expects "user" key for phone
        "otp": otp,
      };

      final response = await _apiService.postResponseV2(
        ApiEndPoints().verifyOtp,    // should return "/api/v1/auth/user/verify-otp"
        body: body,
      );

      if (kDebugMode) {
        print("Verify OTP Response: $response");
      }

      final verifyResp = VerifyOtpResponse.fromJson(response);

      if (verifyResp.isSuccess) {
        // Optional: save token & user data here (shared_preferences / secure storage)
        // await _saveAuthData(verifyResp.token!, verifyResp.user!);
        return verifyResp;
      } else {
        throw Exception(verifyResp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository verifyOtp error: $e");
    }
  }

  Future<VerifyOtpResponse> StaffVerifyOtp({
    required String phone,
    required String otp,
  }) async

  {

    try {
      final body = {
        "user": phone,     // backend expects "user" key for phone
        "otp": otp,
      };

      final response = await _apiService.postResponseV2(
        ApiEndPoints().staffVerifyOtp,    // should return "/api/v1/auth/user/verify-otp"
        body: body,
      );

      if (kDebugMode) {
        print("Verify OTP Response: $response");
      }

      final verifyResp = VerifyOtpResponse.fromJson(response);

      if (verifyResp.isSuccess) {
        // Optional: save token & user data here (shared_preferences / secure storage)
        // await _saveAuthData(verifyResp.token!, verifyResp.user!);
        return verifyResp;
      } else {
        throw Exception(verifyResp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository verifyOtp error: $e");
    }
  }

// lib/repositories/auth_repository.dart

  Future<UpdateProfileResponse> updateProfileImage(File imageFile) async {
    try {
      // Optional: get token
      final token = await AuthService.getToken();

      final response = await _apiService.uploadImageMultipart(
        endpoint: ApiEndPoints().updateProfile,
        imageFile: imageFile,
        fieldName: 'image',
        token: token,
        // additionalFields: {'someKey': 'value'}, // if needed later
      );

      if (kDebugMode) {
        print("Update Profile Raw Response: $response");
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
  Future<UpdateProfileResponse> uploadStaffSelfie(File imageFile) async {
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
        print("Update Profile Raw Response: $response");
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

  // lib/repositories/auth_repository.dart

  Future<BioProfileResponse> updateBioData({
    required String name,
    required String gender,
    required String dob,   // format: DD/MM/YYYY as per your UI
    required String bio,
  }) async {
    try {
      final body = {
        "name": name,
        "gender": gender,
        "DOB": dob,
        "bio": bio,
      };

      final response = await _apiService.postResponseV3(
        ApiEndPoints().updateBioData,   // → "/api/v1/auth/user/user-Bio-Data"
        body: body,
      );

      if (kDebugMode) {
        print("Update Bio Data Response: $response");
      }

      final bioResp = BioProfileResponse.fromJson(response);

      if (bioResp.isSuccess) {
        return bioResp;
      } else {
        throw Exception(bioResp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateBioData error: $e");
    }
  }

  // lib/repositories/auth_repository.dart

  Future<AreaOfInterestResponse> updateAreaOfInterest({
    required List<String> interests,
  }) async

  {
    try {
      final body = {
        "areaOfInterest": interests.map((title) => {"title": title}).toList(),
      };

      final response = await _apiService.postResponseV3(
        ApiEndPoints().updateAreaOfInterest,
        body: body,
      );

      if (kDebugMode) {
        print("Update Area of Interest Response: $response");
      }

      final resp = AreaOfInterestResponse.fromJson(response);
      print("......$resp");

      if (resp.isSuccess) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateAreaOfInterest error: $e");
    }
  }

  // lib/repositories/auth_repository.dart

  Future<LanguageUpdateResponse> updateUserLanguage({
    required String language,
  }) async {
    try {
      final body = {
        "Language": language,
      };

      final response = await _apiService.postResponseV3(
        ApiEndPoints().updateLanguage,
        body: body,
      );

      if (kDebugMode) {
        print("Update Language Response: $response");
      }

      final langResp = LanguageUpdateResponse.fromJson(response);

      if (langResp.isSuccess) {
        return langResp;
      } else {
        throw Exception(langResp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateUserLanguage error: $e");
    }
  }

  // lib/repositories/staff_repository.dart (or auth_repository.dart)

}