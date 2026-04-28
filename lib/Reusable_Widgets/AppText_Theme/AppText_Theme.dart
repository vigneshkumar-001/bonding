import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String data;
  final FontWeight? fontWeight;
  final double? fontSize;
  final Color? color;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const AppText(
    this.data, {
    Key? key,
    this.fontWeight = FontWeight.normal,
    this.fontSize = 16,
    this.color,
    this.decoration,
    this.textAlign,
    this.style,
    this.overflow,
    this.letterSpacing,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final resolvedStyle = (style ?? defaultStyle).copyWith(
      decoration: decoration,
      color: color ?? style?.color ?? theme.colorScheme.onSurface,
      fontSize: fontSize ?? style?.fontSize ?? defaultStyle.fontSize,
      letterSpacing: letterSpacing ?? style?.letterSpacing,
      overflow: overflow ?? style?.overflow,
      fontWeight: fontWeight ?? style?.fontWeight,
    );

    return Text(
      data,
      textAlign: textAlign ?? TextAlign.left,
      style: resolvedStyle,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
