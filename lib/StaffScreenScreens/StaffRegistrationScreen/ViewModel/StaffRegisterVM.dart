// lib/viewmodels/staff_view_model.dart

import 'dart:io';

import 'package:bonding_app/BondingScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/Model/ProfileModel.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/Model/InterestModel.dart';
import 'package:bonding_app/StaffScreenScreens/ProfileVerficationScreen/Model/ProfileIdModel.dart';
import 'package:bonding_app/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/CallGraphModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/Model/StaffRegisterModel.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
import 'package:flutter/material.dart';


class StaffViewModel extends ChangeNotifier {
  final StaffRepository _staffRepo;

  StaffViewModel(this._staffRepo);

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isRegistering = false;
  String? _errorMessage;
  StaffRegisterResponse? _registerResponse;

  bool get isRegistering => _isRegistering;

  String? get errorMessage => _errorMessage;

  StaffRegisterResponse? get registerResponse => _registerResponse;

  Map<String, bool> onlineStatus = {};

  void setUserOnline(String userId, bool isOnline) {
    onlineStatus[userId] = isOnline;
    notifyListeners();
  }

  bool isOnline(String userId) {
    return onlineStatus[userId] ?? false;
  }



  // ─── Register staff ───────────────────────────────────────────────────────
  Future<bool> registerStaff({
    required String phone,
    required String name,
    required String email,
    required String city,
    required String dob,
  }) async {
    _isRegistering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _registerResponse = await _staffRepo.registerStaff(
        phone: phone,
        name: name,
        email: email,
        city: city,
        dob: dob,
      );

      _isRegistering = false;
      notifyListeners();
      return _registerResponse!.isSuccess;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  // lib/viewmodels/staff_view_model.dart

// Add these fields/methods to existing StaffViewModel (or create new if separate)

  bool _isVerifyingId = false;
  String? _idVerifyError;
  StaffIdVerifyResponse? _idVerifyResponse;

  bool get isVerifyingId => _isVerifyingId;

  String? get idVerifyError => _idVerifyError;

  StaffIdVerifyResponse? get idVerifyResponse => _idVerifyResponse;

  Future<bool> verifyStaffId({
    required String idType,
    required String idNumber,
  }) async {
    _isVerifyingId = true;
    _idVerifyError = null;
    notifyListeners();

    try {
      _idVerifyResponse = await _staffRepo.verifyStaffId(
        idType: idType,
        idNumber: idNumber,
      );

      _isVerifyingId = false;
      notifyListeners();
      return _idVerifyResponse!.isSuccess;
    } catch (e) {
      _idVerifyError = e.toString().replaceFirst('Exception: ', '');
      _isVerifyingId = false;
      notifyListeners();
      return false;
    }
  }

  // Add these fields
  File? _selectedProfileImage;
  bool _isUploading = false;
  String? _uploadError;
  UpdateProfileResponse? _updateResponse;

  File? get selectedProfileImage => _selectedProfileImage;

  bool get isUploading => _isUploading;

  String? get uploadError => _uploadError;

  UpdateProfileResponse? get updateResponse => _updateResponse;

// Method to set image from UI
  void setProfileImage(File? image) {
    _selectedProfileImage = image;
    _uploadError = null;
    notifyListeners();
  }

// Upload method
  Future<bool> uploadProfileImage() async {
    if (_selectedProfileImage == null) {
      _uploadError = "No image selected";
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      _updateResponse =
      await _staffRepo.updateProfileImage(_selectedProfileImage!);
      _isUploading = false;

      if (_updateResponse!.isSuccess &&
          _updateResponse!.data?.imageUrl != null) {
        // Optional: save updated user data / image url locally
        notifyListeners();
        return true;
      } else {
        _uploadError = _updateResponse!.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _uploadError = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

// Add these fields
  bool _isUpdatingInterests = false;
  String? _interestError;
  AreaOfInterestResponse? _interestResponse;

  bool get isUpdatingInterests => _isUpdatingInterests;

  String? get interestError => _interestError;

  AreaOfInterestResponse? get interestResponse => _interestResponse;

// Method
  Future<bool> updateStaffAreaOfInterest(List<String> selectedTitles) async {
    if (selectedTitles.length < 3) {
      _interestError = "Please select at least 3 interests";
      notifyListeners();
      return false;
    }

    _isUpdatingInterests = true;
    _interestError = null;
    notifyListeners();

    try {
      _interestResponse = await _staffRepo.updateStaffAreaOfInterest(
        interests: selectedTitles,
      );

      _isUpdatingInterests = false;
      notifyListeners();
      return _interestResponse!.isSuccess;
    } catch (e) {
      _interestError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingInterests = false;
      notifyListeners();
      return false;
    }
  }

// lib/viewmodels/staff_view_model.dart

// Add these fields
  List<StaffDataProfile> _staffList = [];

  bool _isFetchingStaff = false;
  String? _staffFetchError;

  List<StaffDataProfile> get staffList => _staffList;

  bool get isFetchingStaff => _isFetchingStaff;

  String? get staffFetchError => _staffFetchError;

// New method

  void updateStaffPresence(List<dynamic> socketData) {
    for (var item in socketData) {
      final memberId = item["memberID"];
      final isOnline = item["isOnline"];

      final index =
      staffList.indexWhere((s) => s.memberID == memberId);

      if (index != -1) {
        staffList[index] = staffList[index].copyWith(
          isOnline: isOnline,
        );
      }
    }

    notifyListeners();
  }

  Future<void> fetchStaffDetails() async {
    _isFetchingStaff = true;
    _staffFetchError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffDetails();

      // Fixed line:
      _staffList = (response.data as List<StaffDataProfile>?) ?? [];
      _isFetchingStaff = false;
      notifyListeners();
    } catch (e) {
      _staffFetchError = e.toString().replaceFirst('Exception: ', '');
      _isFetchingStaff = false;
      notifyListeners();
    }
  }

  // lib/viewmodels/staff_view_model.dart

// Add these fields
  StaffSingleProfile? _currentStaff;
  bool _isFetchingSingleStaff = false;
  String? _singleStaffError;

  StaffSingleProfile? get currentStaff => _currentStaff;
  bool get isFetchingSingleStaff => _isFetchingSingleStaff;
  String? get singleStaffError => _singleStaffError;

// New method
  Future<void> fetchStaffSingleData() async {
    _isFetchingSingleStaff = true;
    _singleStaffError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffSingleData();
      _currentStaff = response.data;
      _isFetchingSingleStaff = false;
      notifyListeners();
    } catch (e) {
      _singleStaffError = e.toString().replaceFirst('Exception: ', '');
      _isFetchingSingleStaff = false;
      notifyListeners();
    }
  }


  List<CallHistoryItem> _callHistory = [];
  bool _isLoading = false;


  List<CallHistoryItem> get callHistory => _callHistory;
  bool get isLoading => _isLoading;


  Future<void> fetchCallHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffCallHistory();
      _callHistory = response.data ?? [];
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Call history error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Refresh
  Future<void> refresh() => fetchCallHistory();

  int _callsToday = 0;
  int _totalMinutes = 0;
  bool _isFetchingCallStats = false;
  String? _callStatsError;

  int get callsToday => _callsToday;
  int get totalMinutes => _totalMinutes;
  bool get isFetchingCallStats => _isFetchingCallStats;
  String? get callStatsError => _callStatsError;

  Future<void> fetchStaffCallStats() async {
    _isFetchingCallStats = true;
    _callStatsError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffCallStats(); // or walletRepo
      if (response.status && response.data != null) {
        _callsToday = response.data!.callsToday;
        _totalMinutes = response.data!.totalMinutes;
      }
    } catch (e) {
      _callStatsError = e.toString();
    } finally {
      _isFetchingCallStats = false;
      notifyListeners();
    }
  }

  List<WeeklyCallData> _weeklyCallGraph = [];
  bool _isFetchingWeeklyGraph = false;
  String? _weeklyGraphError;

  List<WeeklyCallData> get weeklyCallGraph => _weeklyCallGraph;
  bool get isFetchingWeeklyGraph => _isFetchingWeeklyGraph;
  String? get weeklyGraphError => _weeklyGraphError;

  Future<void> fetchWeeklyCallGraph() async {
    _isFetchingWeeklyGraph = true;
    _weeklyGraphError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getWeeklyCallGraph(); // or your repo
      if (response.status && response.data != null) {
        _weeklyCallGraph = response.data!;
      }
    } catch (e) {
      _weeklyGraphError = e.toString();
    } finally {
      _isFetchingWeeklyGraph = false;
      notifyListeners();
    }
  }

  String? getStaffIdByMemberId(String memberId) {
    // If you have _currentStaff and it's the logged-in staff
    if (_currentStaff != null && _currentStaff!.memberID == memberId) {
      return _currentStaff!.id; // assuming 'id' is the _id field
    }

    // If you have staffList (all staff)
    final staff = _staffList.firstWhere(
          (s) => s.memberID == memberId,
      // fallback empty
    );
    return staff.id.isNotEmpty ? staff.id : null;
  }
}