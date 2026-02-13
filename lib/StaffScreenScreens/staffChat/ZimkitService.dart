import 'package:flutter/material.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class ZimConnectionService {
  static bool isConnected = false;

  static Future<bool> ensureConnected(
      BuildContext context, {
        required String userId,
        required String userName,
        String? avatarUrl,
      }) async {
    if (isConnected) return true;

    try {
      await ZIMKit().connectUser(
        id: userId,
        name: userName,
        avatarUrl: avatarUrl ?? '',
      );
      isConnected = true;
      debugPrint("ZIMKit connected: $userId");
      return true;
    } catch (e) {
      debugPrint("ZIMKit connection failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Chat connection failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  static Future<void> disconnect() async {
    await ZIMKit().disconnectUser();
    isConnected = false;
  }
}