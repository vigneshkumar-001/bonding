import 'package:bonding_app/BondingScreens/PrivacyPolicy/Repository/settings_repository.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyVM extends ChangeNotifier {
  final SettingsRepository repo;
  PrivacyPolicyVM(this.repo);

  bool isLoading = false;
  String? errorMessage;

  String title = "";
  String content = "";

  Future<void> fetchPrivacyPolicy() async {
    isLoading = true;
    errorMessage = null;

    // ✅ clear old values so UI is consistent
    title = "";
    content = "";

    notifyListeners();

    try {
      final res = await repo.getPrivacyPolicy(); // returns PrivacyPolicyResponse

      if (res.status == true && res.data != null) {
        title = (res.data!.title ?? "").trim();
        content = (res.data!.content ?? "").trim();
      } else {
        errorMessage = res.message ?? "Failed to load Privacy Policy";
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst("Exception: ", "");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  Future<void> refresh() async {
    await fetchPrivacyPolicy();
  }
}
