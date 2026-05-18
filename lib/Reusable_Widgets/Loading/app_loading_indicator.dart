import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double radius;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.radius = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      radius: radius,
      color: color,
    );
  }
}

