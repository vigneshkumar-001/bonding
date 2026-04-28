import 'package:flutter/material.dart';

@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  final LinearGradient primaryGradient;
  final LinearGradient backgroundGradient;
  final Color online;
  final Color offline;

  const BrandTheme({
    required this.primaryGradient,
    required this.backgroundGradient,
    required this.online,
    required this.offline,
  });

  static BrandTheme of(BuildContext context) {
    final ext = Theme.of(context).extension<BrandTheme>();
    assert(ext != null, 'BrandTheme is not added to ThemeData.extensions');
    return ext!;
  }

  @override
  BrandTheme copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? backgroundGradient,
    Color? online,
    Color? offline,
  }) {
    return BrandTheme(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      online: online ?? this.online,
      offline: offline ?? this.offline,
    );
  }

  @override
  ThemeExtension<BrandTheme> lerp(
    ThemeExtension<BrandTheme>? other,
    double t,
  ) {
    if (other is! BrandTheme) return this;
    return BrandTheme(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
    );
  }
}

