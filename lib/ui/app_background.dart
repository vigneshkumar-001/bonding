import 'package:bonding_app/theme/brand_theme.dart';
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: brand.backgroundGradient),
      child: SizedBox.expand(child: child),
    );
  }
}
