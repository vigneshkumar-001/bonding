import 'package:bonding_app/Bonding_Utils/ColorHandlers/AppColors.dart';
import 'package:flutter/material.dart';

class UnderDevelopmentWidgets {
  static void buildUnderDevelopmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Feature in Development',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: appColors.textBlackLight, // ✅ correct usage
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature is currently under development.\nStay tuned for updates!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: appColors.greyTextLight, // ✅ correct usage
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: (){
                    Navigator.pop(context); // ✅ This will close dialog
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient:   const LinearGradient(
                        colors: [
                          Color(0xFF7A5CFF),
                          Color(0xFFFF5CA8),
                        ],
                      ),
                    ),
                    child: Center(
                      child:   const Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}
