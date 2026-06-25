import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/InterestScreen.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen2.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Services/AdminCall/admin_call_handler.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/staff_route_gate.dart';
import 'package:bonding_app/Reusable_Widgets/Loading/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _checkLoginAndStatus();
  }

  final socketService = SocketService();
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
    final accountType = (await AuthService.getAccountType())?.toLowerCase();

    await Future.wait([
      userVM.fetchUserDetails(),
      staffVM.fetchStaffSingleData(),
    ]);

    if (!mounted) return;

    final user = userVM.currentUser;
    final staff = staffVM.currentStaff;
    final staffMemberId = staff?.memberID.trim() ?? '';

    if (staffMemberId.isNotEmpty) {
      socketService.connectStaff(staffMemberId);
      // Start receiving Admin -> Staff verification calls (FCM + socket).
      // Covers ALL staff states incl. pending verification.
      AdminCallHandler().startForStaffSession(staffMemberId: staffMemberId);
    }

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

    if (accountType == AuthService.accountTypeUser && user != null) {
      role = user.role.toLowerCase();
      formStatusStr = user.formStatus;
    } else if (accountType == AuthService.accountTypeStaff && staff != null) {
      role = staff.role.toLowerCase();
      formStatusStr = staff.formStatus;
    } else if (staff != null) {
      role = staff.role.toLowerCase();
      formStatusStr = staff.formStatus;
    } else if (user != null) {
      role = user.role.toLowerCase();
      formStatusStr = user.formStatus;
    }

    AppLogger.log.w("Role detected: $role");
    AppLogger.log.w("Form Status raw: ${formStatusStr ?? 'NULL'}");

    final status = int.tryParse(formStatusStr ?? '0') ?? 0;
    print("Parsed status: $status");

    // ────────────────────────────────────────────────
    // STAFF FLOW (only isApproved matters here)
    // ────────────────────────────────────────────────
    if (role == 'staff') {
      // Single source of truth (staff_route_gate.dart): a PENDING ("0") or
      // REJECTED ("2") staff is gated out of the dashboard even if the form is
      // complete. They still receive the admin verification call separately.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => resolveStaffHome(staff!)),
      );
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
            colors: [Color(0xFF17131F), Color(0xFF241024), Color(0xFF120C18)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/Images/appLogo.png",
                height: 80,
                fit: BoxFit.contain,
              ),
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
              const AppLoadingIndicator(radius: 14, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
