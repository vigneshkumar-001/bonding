import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bonding_app/app/navigator_key.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Utils {
  static double averageRating(List<int> rating) {
    var avgRating = 0;
    for (int i = 0; i < rating.length; i++) {
      avgRating = avgRating + rating[i];
    }
    return double.parse((avgRating / rating.length).toStringAsFixed(1));
  }

  static void fieldFocusChange(
      BuildContext context,
      FocusNode current,
      FocusNode nextFocus,
      ) {
    current.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  static void _snackBarFallback(String message, Color backgroundColor) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint(message);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  static void topError(String message) {
    _topSnack(
      message: message,
      backgroundColor: const Color(0xFFB00020),
      icon: Icons.error_outline_rounded,
    );
  }

  static void topSuccess(String message) {
    _topSnack(
      message: message,
      backgroundColor: const Color(0xFF1B5E20),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void _topSnack({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint(message);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final topInset = MediaQuery.of(context).padding.top;
    final marginTop = topInset + kToolbarHeight + 8;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.fromLTRB(16, marginTop, 16, 16),
        duration: const Duration(seconds: 4),
        content: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static snackBar(String message) {
    // Use the same modern in-app UI everywhere (avoid Fluttertoast style mismatch).
    topSuccess(message);
  }

  static snackBarErrorMessage(String message) {
    // Use the same modern in-app UI everywhere (avoid Fluttertoast style mismatch).
    topError(message);
  }

  static snackBar1(String message, BuildContext context) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(message, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  static snackBarErrorMessage1(String message, BuildContext context) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message, style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
