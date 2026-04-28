import 'package:flutter/material.dart';

Color _hsv(double h, double s, double v) =>
    HSVColor.fromAHSV(1, h, s, v).toColor();

LinearGradient seededCardGradient(String seed) {
  final hash = seed.hashCode;
  final baseHue = (hash.abs() % 360).toDouble();
  final h1 = baseHue;
  final h2 = (baseHue + 28) % 360;
  final h3 = (baseHue + 55) % 360;

  // Dark, premium gradients (works on dark background).
  final c1 = _hsv(h1, 0.55, 0.35);
  final c2 = _hsv(h2, 0.70, 0.28);
  final c3 = _hsv(h3, 0.78, 0.20);

  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.0, 0.55, 1.0],
    colors: [c1, c2, c3],
  );
}

String initialsFromName(String? name) {
  final value = (name ?? '').trim();
  if (value.isEmpty) return '?';
  final parts = value
      .split(RegExp(r'\s+'))
      .where((p) => p.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';

  final hasLetter = RegExp(r'\p{L}', unicode: true);
  final words = parts.where((p) => hasLetter.hasMatch(p)).toList();
  if (words.isEmpty) return '?';

  String firstChar(String s) => s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
  if (words.length == 1) return firstChar(words.first);
  final a = firstChar(words.first);
  final b = firstChar(words.last);
  return '$a$b';
}

double seededOpacity(String seed, {double min = 0.06, double max = 0.14}) {
  final h = seed.hashCode.abs();
  final t = (h % 1000) / 1000.0;
  return min + (max - min) * t;
}
