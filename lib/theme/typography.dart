import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's baked-in typography. UI text (headings, labels, body) uses
/// Space Grotesk — a bold geometric sans that suits the neo-brutalist look —
/// while all figures (KPI values, amounts, table numbers) use JetBrains Mono,
/// a monospaced face so columns of numbers line up perfectly.

/// Applies the app's UI font (Space Grotesk) to [base], preserving the scheme's
/// per-style sizes/weights. Used for the global light/dark text themes.
TextTheme appTextTheme(TextTheme base) => GoogleFonts.spaceGroteskTextTheme(base);

/// Condensed face (Roboto Condensed) for dense table text — category names and
/// the S.No / Date / Description / Bank cells. It packs long descriptions into
/// tighter columns while staying highly legible; amounts keep JetBrains Mono so
/// figures stay monospaced and aligned. Bundled as an asset (see pubspec) since
/// google_fonts no longer ships a standalone Roboto Condensed family.
TextStyle tableTextStyle({
  double fontSize = 14.5,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double? height,
}) => TextStyle(
  fontFamily: 'RobotoCondensed',
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
);

/// Display style for prominent figures (KPI tiles, dialog headlines). Built on
/// [base] so it keeps the surrounding size, then switched to JetBrains Mono with
/// tabular figures so digits stay monospaced and aligned.
TextStyle? dashboardNumberStyle(
  TextStyle? base, {
  Color? color,
  FontWeight fontWeight = FontWeight.w700,
}) {
  if (base == null) return null;
  return GoogleFonts.jetBrainsMono(
    textStyle: base,
    color: color,
    fontWeight: fontWeight,
    letterSpacing: 0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Compact style for figures inside data tables (transaction amounts, category
/// totals). JetBrains Mono with tabular figures keeps the amount column aligned.
TextStyle tableNumberStyle(
  ThemeData theme, {
  Color? color,
  FontWeight fontWeight = FontWeight.w700,
  double? fontSize,
}) {
  return GoogleFonts.jetBrainsMono(
    color: color ?? theme.colorScheme.onSurface,
    fontSize: fontSize ?? 12.5,
    fontWeight: fontWeight,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
