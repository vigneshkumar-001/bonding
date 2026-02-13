import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/AddProfileScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/InterestScreen.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen2.dart';
import 'package:bonding_app/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/StaffSelectInterestScreen/StaffSelectInterestScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _checkLoginAndStatus();
  }

  Future<void> _checkLoginAndStatus() async {
    // Show splash for a moment (branding/animation)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();

    if (!isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SplashScreen2()),
        );
      }
      return;
    }

    // Logged in → fetch fresh data
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final staffVM = Provider.of<StaffViewModel>(context, listen: false);

    await Future.wait([
      userVM.fetchUserDetails(),
      staffVM.fetchStaffSingleData(),
    ]);

    if (!mounted) return;

    final user = userVM.currentUser;
    final staff = staffVM.currentStaff;

    // No profile at all → back to onboarding / login flow
    if (user == null && staff == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen2()),
      );
      return;
    }

    // Decide role and form status
    String? role;
    String? formStatusStr;

    if (staff != null) {
      role = staff.role?.toLowerCase() ?? 'staff';
      formStatusStr = staff.formStatus;
    } else if (user != null) {
      role = user.role?.toLowerCase() ?? 'user';
      formStatusStr = user.formStatus;
    }

    print("Role detected: $role");
    print("Form Status raw: ${formStatusStr ?? 'NULL'}");

    final status = int.tryParse(formStatusStr ?? '0') ?? 0;
    print("Parsed status: $status");

    // ────────────────────────────────────────────────
    // STAFF FLOW (only isApproved matters here)
    // ────────────────────────────────────────────────
    if (role == 'staff') {
      if (status <= 0 || status == null) {
        // Not even basic registration completed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddProfile()), // or your starting screen
        );
      }
      else if (status == 1) {
        // Basic profile done → verification step
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LiveVerificationScreen()),
        );
      }
      else if (status == 2) {
        // Documents submitted → now check approval status
        final approval = staff!.isApproved?.toLowerCase().trim() ?? 'pending';

        if (approval == '1') {
          // Approved → go to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ApprovedScreen()),
          );
        }
        else if (approval.contains('2') || approval == 'declined' || approval == 'not approved') {
          // Rejected
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerificationUnsuccessScreen()),
          );
        }
        else {
          // pending / under review / null / empty / anything else
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const VerificationInprogressScreen()),
          );
        }
      }
      else if (status >= 3) {
        // Verification completed → main dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffBottomBar()),
        );
      }
      else {
        // Unknown / fallback
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffBottomBar()),
        );
      }
    }

    // ────────────────────────────────────────────────
    // USER FLOW (no isApproved needed)
    // ────────────────────────────────────────────────
    else {
      if (status == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IdentityScreen()),
        );
      } else if (status == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterestScreen()),
        );
      } else if (status == 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterestLanguageScreen()),
        );
      } else {
        // Completed → main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainBottomBar()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF5A1F3F),
              Color(0xFF3A152A),
              Color(0xFF140810),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/Images/bonding.svg", height: 80),
              const SizedBox(height: 16),
              Container(
                width: 140,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}