import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double radius;
  final Color? color;
  final bool center;

  const AppLoader({
    super.key,
    this.radius = 14,
    this.color,
    this.center = false,
  });

  const AppLoader.center({
    super.key,
    this.radius = 14,
    this.color,
  }) : center = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final indicator = CupertinoActivityIndicator(
      radius: radius,
      color: color ?? cs.onSurfaceVariant,
    );

    if (!center) return indicator;
    return Center(child: indicator);
  }
}

