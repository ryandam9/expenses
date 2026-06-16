import 'package:flutter/material.dart';

/// Shared surface helpers for the app's "refined brutalist" look: crisp slate
/// borders (not pure black) and a single small, hard offset shadow. Bold and
/// tactile, but calmer than a classic neo-brutalist treatment — fewer, quieter
/// shadows and one consistent edge colour.

/// The outline colour used by panels, cards and controls — a slate that reads
/// as a deliberate edge without the harshness of pure black.
Color brutalLine(ColorScheme cs) => cs.brightness == Brightness.dark
    ? const Color(0xFF515667)
    : const Color(0xFF23232B);

/// A hard offset shadow (no blur) that gives a card a tactile, printed feel.
/// [color] defaults to the slate outline so an element's edge and its shadow
/// agree; pass a colour for an accented lift.
BoxShadow brutalShadow(
  ColorScheme cs, {
  double dx = 3,
  double dy = 3,
  Color? color,
}) => BoxShadow(
  color: (color ?? brutalLine(cs)).withValues(
    alpha: cs.brightness == Brightness.dark ? 0.5 : 0.9,
  ),
  offset: Offset(dx, dy),
  blurRadius: 0,
  spreadRadius: 0,
);

/// A complete app panel decoration: a slate border plus one hard offset shadow.
BoxDecoration brutalBox(
  ColorScheme cs, {
  Color? color,
  double radius = 11,
  double dx = 3,
  double dy = 3,
  Color? shadowColor,
  double borderWidth = 1.5,
}) => BoxDecoration(
  color: color ?? cs.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: brutalLine(cs), width: borderWidth),
  boxShadow: [brutalShadow(cs, dx: dx, dy: dy, color: shadowColor)],
);
