import 'package:flutter/material.dart';

import 'package:bonding_app/theme/brand_theme.dart';

class GradientAppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;

  const GradientAppText({
    super.key,
    required this.text,
    required this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(context);
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return brand.primaryGradient.createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: fontWeight ?? FontWeight.w300,
        ),
      ),
    );
  }
}
