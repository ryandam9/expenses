import 'package:flutter/material.dart';

/// Shared surface helpers. The original app used a hard neo-brutalist
/// treatment; these helpers keep the same API while rendering calmer,
/// production-dashboard surfaces with fine borders and soft depth.

/// The outline colour used by custom panels and controls.
Color brutalLine(ColorScheme cs) => cs.brightness == Brightness.dark
    ? const Color(0xFF3B4354)
    : const Color(0xFFD7DCE7);

/// A soft shadow that reads as elevation without overpowering dense data UI.
BoxShadow brutalShadow(
  ColorScheme cs, {
  double dx = 4,
  double dy = 4,
  Color? color,
}) => BoxShadow(
  color: (color ?? cs.shadow).withValues(
    alpha: cs.brightness == Brightness.dark ? 0.28 : 0.12,
  ),
  offset: Offset(dx, dy),
  blurRadius: 18,
  spreadRadius: -8,
);

/// A complete app panel decoration.
BoxDecoration brutalBox(
  ColorScheme cs, {
  Color? color,
  double radius = 10,
  double dx = 0,
  double dy = 8,
  Color? shadowColor,
  double borderWidth = 1,
}) => BoxDecoration(
  color: color ?? cs.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: brutalLine(cs), width: borderWidth),
  boxShadow: [brutalShadow(cs, dx: dx, dy: dy, color: shadowColor)],
);
