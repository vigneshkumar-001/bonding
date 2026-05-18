import 'package:flutter/cupertino.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double radius;
  final Color? color;
  final double? strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.radius = 12,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(radius: radius, color: color);
  }
}
