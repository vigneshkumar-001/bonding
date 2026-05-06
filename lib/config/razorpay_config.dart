import 'package:flutter/foundation.dart';

// Razorpay config:
// - Debug/profile: allows a test key fallback (to avoid blocking local dev).
// - Release: requires `--dart-define` (no keys shipped to stores).
String get razorpayKey {
  const fromEnv = String.fromEnvironment('RAZORPAY_KEY', defaultValue: '');
  if (fromEnv.isNotEmpty) return fromEnv;

  if (!kReleaseMode) {
    // TODO: replace with your own test key for local dev (or keep empty).
    return '';
  }

  return '';
}

void assertRazorpayConfig() {
  if (razorpayKey.isEmpty) {
    throw StateError(
      'Missing Razorpay key. Provide --dart-define=RAZORPAY_KEY=... for release builds.',
    );
  }
}
