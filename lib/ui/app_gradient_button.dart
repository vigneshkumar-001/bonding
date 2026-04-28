import 'package:bonding_app/theme/brand_theme.dart';
import 'package:flutter/material.dart';

class AppGradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  const AppGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandTheme.of(context);
    final enabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Ink(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: enabled
                ? brand.primaryGradient
                : LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.outlineVariant,
                      Theme.of(context).colorScheme.outline,
                    ],
                  ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

