import 'package:flutter/material.dart';

TextStyle? dashboardNumberStyle(
  TextStyle? base, {
  Color? color,
  FontWeight fontWeight = FontWeight.w800,
}) {
  return base?.copyWith(
    color: color,
    fontWeight: fontWeight,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

TextStyle tableNumberStyle(
  ThemeData theme, {
  Color? color,
  FontWeight fontWeight = FontWeight.w800,
  double? fontSize,
}) {
  return TextStyle(
    color: color ?? theme.colorScheme.onSurface,
    fontSize: fontSize ?? 12.5,
    fontWeight: fontWeight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
