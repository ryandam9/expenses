import 'package:flutter/material.dart';

/// Neo-brutalist surface helpers: flat fills, thick high-contrast borders and
/// hard (zero-blur) offset shadows. Shared so every panel in the app speaks the
/// same chunky visual language.

/// The strong outline colour: near-black on light surfaces, a bright near-white
/// on dark ones, so borders always read hard against the fill.
Color brutalLine(ColorScheme cs) =>
    cs.brightness == Brightness.dark ? const Color(0xFFEDEDED) : const Color(0xFF111111);

/// A solid, un-blurred drop shadow offset down-right — the signature
/// neo-brutalist "sticker" lift.
BoxShadow brutalShadow(ColorScheme cs,
        {double dx = 4, double dy = 4, Color? color}) =>
    BoxShadow(
      color: color ?? brutalLine(cs),
      offset: Offset(dx, dy),
      blurRadius: 0,
    );

/// A complete brutalist panel decoration.
BoxDecoration brutalBox(
  ColorScheme cs, {
  Color? color,
  double radius = 14,
  double dx = 4,
  double dy = 4,
  Color? shadowColor,
  double borderWidth = 2,
}) =>
    BoxDecoration(
      color: color ?? cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: brutalLine(cs), width: borderWidth),
      boxShadow: [brutalShadow(cs, dx: dx, dy: dy, color: shadowColor)],
    );
