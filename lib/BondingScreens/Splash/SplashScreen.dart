import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/BondingScreens/BottomNavBar/BottomNavBar.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/HomeScreen.dart';
import 'package:bonding_app/BondingScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/AddProfile/AddProfileScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:bonding_app/BondingScreens/LoginScreens/InterestScreen/InterestScreen.dart';
import 'package:bonding_app/BondingScreens/Splash/SplashScreen2.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Socket/socket_service.dart';
import 'package:bonding_app/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:bonding_app/StaffScreenScreens/StaffSelectInterestScreen/StaffSelectInterestScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:bonding_app/ui/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    try {
      await Future.wait([
        userVM.fetchUserDetails(),
        staffVM.fetchStaffSingleData(),
      ]).timeout(const Duration(seconds: 20));
    } catch (e, st) {
      AppLogger.log.e("Splash fetch failed: $e", stackTrace: st);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen2()),
      );
      return;
    }

    // Connect socket only after we have the latest staff details.
    final memberId = staffVM.currentStaff?.memberID?.trim() ?? '';
    if (memberId.isNotEmpty) {
      try {
        await socketService
            .connectStaff(memberId)
            .timeout(const Duration(seconds: 10));
      } catch (e, st) {
        AppLogger.log.w("Socket connect skipped: $e");
        AppLogger.log.w("Socket connect stack: $st");
      }
    }

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

    AppLogger.log.w("Role detected: $role");
    AppLogger.log.w("Form Status raw: ${formStatusStr ?? 'NULL'}");

    final formStatusNormalized = (formStatusStr ?? '').trim();
    final hasFormStatus =
        formStatusNormalized.isNotEmpty &&
        formStatusNormalized.toLowerCase() != 'null';
    final int? status = hasFormStatus
        ? int.tryParse(formStatusNormalized)
        : null;
    print("Parsed status: ${status?.toString() ?? 'NULL'}");

    // ────────────────────────────────────────────────
    // STAFF FLOW (only isApproved matters here)
    // ────────────────────────────────────────────────
    if (role == 'staff') {
      // If backend doesn't send formStatus, fall back to isApproved to avoid
      // incorrectly sending already-registered staff to onboarding screens.
      if (status == null) {
        final approval = staff?.isApproved?.toString().trim().toLowerCase();

        if (approval == '1') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StaffBottomBar()),
          );
          return;
        }

        if (approval == '2' ||
            approval == 'declined' ||
            approval == 'not approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationUnsuccessScreen(),
            ),
          );
          return;
        }

        // Pending/unknown approval state: keep them in verification flow.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VerificationInprogressScreen(),
          ),
        );
        return;
      }

      if (status <= 0) {
        // Not even basic registration completed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AddProfile(),
          ), // or your starting screen
        );
      } else if (status == 1) {
        // Basic profile done → verification step
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LiveVerificationScreen()),
        );
      } else if (status == 2) {
        // Documents submitted → now check approval status
        final approval =
            staff?.isApproved?.toString().trim().toLowerCase() ?? 'pending';

        if (approval == '1') {
          // Approved → go to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ApprovedScreen()),
          );
        } else if (approval.contains('2') ||
            approval == 'declined' ||
            approval == 'not approved') {
          // Rejected
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationUnsuccessScreen(),
            ),
          );
        } else {
          // pending / under review / null / empty / anything else
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationInprogressScreen(),
            ),
          );
        }
      } else if (status >= 3) {
        // Verification completed → main dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffBottomBar()),
        );
      } else {
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
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/Images/bonding.png", height: 80),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.onSurfaceVariant,
              ),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
