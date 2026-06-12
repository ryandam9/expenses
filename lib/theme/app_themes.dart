import 'package:flutter/material.dart';

/// A single selectable theme. A theme is described by three seed colours
/// (primary / secondary / tertiary) — the full [ThemeData] for either
/// brightness is derived from them via [ColorScheme.fromSeed] — plus a
/// dedicated chart palette of six hand-picked, mutually distinct colours so
/// visualisations stay legible no matter how many categories appear.
class AppTheme {
  final String id;
  final String name;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  /// Colours used for chart series/segments, ordered for maximum contrast
  /// between neighbours.
  final List<Color> chartColors;

  const AppTheme({
    required this.id,
    required this.name,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.chartColors,
  });

  /// The colours used by charts and ambient accents so visualisations share
  /// the theme's identity instead of a generic, off-theme palette.
  List<Color> get palette => chartColors;

  ThemeData themeData(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 19,
          color: scheme.onSurface,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Builds [count] distinct, on-theme colours from a [base] palette. The base
/// colours are used first; when more are needed than the palette provides,
/// progressively lighter tints are generated so neighbouring chart segments
/// stay visually distinct.
List<Color> buildChartColors(List<Color> base, int count) {
  if (base.isEmpty || count <= 0) return const [];
  final out = <Color>[];
  for (var i = 0; i < count; i++) {
    final c = base[i % base.length];
    final cycle = i ~/ base.length;
    if (cycle == 0) {
      out.add(c);
    } else {
      final hsl = HSLColor.fromColor(c);
      final l = (hsl.lightness + 0.14 * cycle).clamp(0.25, 0.85);
      final s = (hsl.saturation - 0.05 * cycle).clamp(0.2, 1.0);
      out.add(hsl.withLightness(l).withSaturation(s).toColor());
    }
  }
  return out;
}

/// The selectable themes: a curated set of balanced, modern palettes. Each
/// keeps a calm primary for chrome and a high-contrast six-colour chart
/// palette for data.
const appThemes = <AppTheme>[
  AppTheme(
    id: 'indigo',
    name: 'Indigo',
    icon: Icons.auto_awesome,
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF0EA5E9),
    tertiary: Color(0xFFF59E0B),
    chartColors: [
      Color(0xFF4F46E5),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ],
  ),
  AppTheme(
    id: 'emerald',
    name: 'Emerald',
    icon: Icons.eco,
    primary: Color(0xFF059669),
    secondary: Color(0xFF0D9488),
    tertiary: Color(0xFFF59E0B),
    chartColors: [
      Color(0xFF059669),
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFF14B8A6),
      Color(0xFFA855F7),
      Color(0xFF84CC16),
    ],
  ),
  AppTheme(
    id: 'ocean',
    name: 'Ocean',
    icon: Icons.water,
    primary: Color(0xFF0369A1),
    secondary: Color(0xFF06B6D4),
    tertiary: Color(0xFF6366F1),
    chartColors: [
      Color(0xFF0369A1),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
      Color(0xFFEC4899),
    ],
  ),
  AppTheme(
    id: 'sunset',
    name: 'Sunset',
    icon: Icons.wb_twilight,
    primary: Color(0xFFEA580C),
    secondary: Color(0xFFDB2777),
    tertiary: Color(0xFFF59E0B),
    chartColors: [
      Color(0xFFEA580C),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFFDB2777),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
    ],
  ),
  AppTheme(
    id: 'grape',
    name: 'Grape',
    icon: Icons.bubble_chart,
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFC026D3),
    tertiary: Color(0xFF0EA5E9),
    chartColors: [
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
    ],
  ),
  AppTheme(
    id: 'forest',
    name: 'Forest',
    icon: Icons.forest,
    primary: Color(0xFF15803D),
    secondary: Color(0xFF65A30D),
    tertiary: Color(0xFF0D9488),
    chartColors: [
      Color(0xFF15803D),
      Color(0xFFCA8A04),
      Color(0xFF2563EB),
      Color(0xFF65A30D),
      Color(0xFF9333EA),
      Color(0xFF0D9488),
    ],
  ),
  AppTheme(
    id: 'crimson',
    name: 'Crimson',
    icon: Icons.local_fire_department,
    primary: Color(0xFFDC2626),
    secondary: Color(0xFFF97316),
    tertiary: Color(0xFFD97706),
    chartColors: [
      Color(0xFFDC2626),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
      Color(0xFF10B981),
      Color(0xFFF97316),
    ],
  ),
  AppTheme(
    id: 'graphite',
    name: 'Graphite',
    icon: Icons.tonality,
    primary: Color(0xFF334155),
    secondary: Color(0xFF0EA5E9),
    tertiary: Color(0xFF64748B),
    chartColors: [
      Color(0xFF334155),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ],
  ),
  AppTheme(
    id: 'rose',
    name: 'Rosé',
    icon: Icons.favorite,
    primary: Color(0xFFE11D48),
    secondary: Color(0xFFEC4899),
    tertiary: Color(0xFF8B5CF6),
    chartColors: [
      Color(0xFFE11D48),
      Color(0xFF8B5CF6),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF10B981),
    ],
  ),
];
