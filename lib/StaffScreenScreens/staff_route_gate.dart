// lib/StaffScreenScreens/staff_route_gate.dart
//
// Single source of truth for "where should this staff land" based on
// registration progress (formStatus) AND admin approval (isApproved).
//
// isApproved: "0" = pending · "1" = approved · "2" = rejected.
//
// IMPORTANT: a PENDING ("0") or REJECTED ("2") staff must NEVER reach the main
// dashboard (StaffBottomBar) — even if their form is fully complete. They can
// still receive the admin verification video call (that handler is started
// separately for every logged-in staff session).

import 'package:flutter/material.dart';

import 'package:bonding_app/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:bonding_app/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:bonding_app/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:bonding_app/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:bonding_app/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';

bool staffIsApproved(String? isApproved) {
  final a = (isApproved ?? '').toLowerCase().trim();
  return a == '1' || a == 'approved';
}

bool staffIsRejected(String? isApproved) {
  final a = (isApproved ?? '').toLowerCase().trim();
  return a == '2' || a.contains('2') || a == 'declined' || a == 'not approved' || a == 'rejected';
}

/// Returns the screen a logged-in staff should start on.
Widget resolveStaffHome(StaffSingleProfile staff) {
  final status = int.tryParse(staff.formStatus ?? '0') ?? 0;

  // Registration steps not finished yet -> keep them in the form flow.
  if (status <= 0) {
    return const StaffRegisterScreen(mode: StaffAuthMode.register);
  }
  if (status == 1) {
    return const LiveVerificationScreen();
  }

  // Form submitted (status >= 2) -> GATE on admin approval.
  if (staffIsRejected(staff.isApproved)) {
    return const VerificationUnsuccessScreen();
  }
  if (!staffIsApproved(staff.isApproved)) {
    // Pending ("0" / null / anything not yet approved).
    return const VerificationInprogressScreen();
  }

  // Approved.
  if (status == 2) {
    // Just approved -> congrats -> interest selection flow.
    return const ApprovedScreen();
  }
  return const StaffBottomBar();
}
