import 'package:bonding_app/BondingScreens/HomeScreen/Repo/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'package:bonding_app/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';

class CommonCallButton extends StatelessWidget {
  final bool enabled;
  final String text;
  final int pricePerMin;
  final bool isVideoCall;

  final String targetUserID;       // staff.memberID (zego)
  final String targetUserName;
  final String targetStaffMongoId; // staff._id (mongo)
  final bool isTargetOnline;

  const CommonCallButton({
    super.key,
    required this.enabled,
    required this.text,
    required this.pricePerMin,
    required this.isVideoCall,
    required this.targetUserID,
    required this.targetUserName,
    required this.targetStaffMongoId,
    required this.isTargetOnline,
  });

  @override
  Widget build(BuildContext context) {
    final callCtrl = context.read<CallController>();

    return GestureDetector(
      onTap: () async {
        await callCtrl.startCall(
          context: context,
          enabled: enabled,
          isTargetOnline: isTargetOnline,
          pricePerMin: pricePerMin,
          isVideoCall: isVideoCall,
          targetUserID: targetUserID,
          targetUserName: targetUserName,
          targetStaffMongoId: targetStaffMongoId,
        );
      },
      child: Opacity(
        opacity: enabled ? 1.0 : 0.55,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFF9251d0), Color(0xFFf56463)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/Images/goldcoin1.png", height: 20),
              const SizedBox(width: 4),
              AppText(text, color: Colors.white, fontWeight: FontWeight.w600),
              const SizedBox(width: 6),
              Icon(isVideoCall ? Icons.video_call : Icons.call, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
