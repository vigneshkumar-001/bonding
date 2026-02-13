import 'dart:convert';

class ApiEndPoints {
  // bitbab
  // final String baseUrl = "https://bondingbackend.onrender.com/api/v1/";
  // final String baseUrl = "http://192.168.0.22:3005/api/v1/";
    final String baseUrl = "https://qbkqz1b4-3005.inc1.devtunnels.ms/api/v1/";

  // final String profileBaseUrl = "https://predictapi.unitythink.com";

  final String login = "auth/user/signup";
  final String verifyOtp = "auth/user/verify-otp";
  final String updateProfile = "auth/user/updateProfile";
  final String updateBioData = "auth/user/user-Bio-Data";
  final String updateAreaOfInterest = "auth/user/area-Of-Interest";
  final String updateLanguage = "auth/user/user-Language";
  final String getUserDetails = "auth/user/getUserDetails";
  final String userBalanceUpdate = "auth/user/userBalanceUpdate";
  final String userCallHistory = "auth/user/userCallHistory";
  final String placeOrder = "auth/user/placeOrder";
  final String confirmPurchase = "auth/user/confirmPurchase";
  final String userDepositHistory = "auth/user/userDepositHistory";

  final String getPaymentsStructure = "auth/user/getPaymentsStructure";







  ////////////// Staff flow ///////////////

final String staffRegister = "staff/staff-data";
  final String staffVerifyOtp = "staff/verify-otps";
  final String staffIdVerify = "staff/staffIdVerify";
  final String updateStaffProfile = "staff/updateProfile";
  final String updateStaffAreaOfInterest = "staff/area-Of-Interest";


  final String getStaffDetails   = "auth/user/getstaffDetails";

  final String getStaffSingleData = "staff/getstaffSingleData";

  final String staffCallHistory = "staff/staffCallHistory";

  final String addBankDetails = "staff/addBankDetails";

  final String getAllBankDetails = "staff/getAllBankDetails";
  final String deleteBankDetails = "staff/deleteBankDetails";

  final String staffWithdraw = "staff/staffWithdraw";

  final String staffWithdrawHistory = "staff/staffWithdrawHistory";

  final String staffCallStats = "staff/getStaffCallStats";

  final String staffWeeklyCallGraph = "staff/getWeeklyCallGraph";




}
