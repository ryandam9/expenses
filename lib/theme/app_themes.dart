import 'package:flutter/material.dart';

/// A single selectable theme. Following the approach used in the companion
/// `attendance-register` app, a theme is described by just three seed colours
/// (primary / secondary / tertiary); the full [ThemeData] for either brightness
/// is derived from them via [ColorScheme.fromSeed]. This keeps every theme
/// structurally identical and lets light/dark mode follow the system.
class AppTheme {
  final String id;
  final String name;
  final IconData icon;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  const AppTheme({
    required this.id,
    required this.name,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });

  /// The seed colours, used to colour charts and accents so visualisations
  /// share the theme's identity instead of a generic, off-theme palette.
  List<Color> get palette => [primary, secondary, tertiary];

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

/// The selectable themes — a neutral Default plus a set of Australian-bird
/// palettes, mirroring the companion attendance-register app.
const appThemes = <AppTheme>[
  AppTheme(
    id: 'default',
    name: 'Default',
    icon: Icons.dashboard_rounded,
    primary: Color(0xFF1A73E8),
    secondary: Color(0xFF5F6368),
    tertiary: Color(0xFF34A853),
  ),
  AppTheme(
    id: 'spotted_pardalote',
    name: 'Spotted Pardalote',
    icon: Icons.emoji_nature,
    primary: Color(0xFFCB0300),
    secondary: Color(0xFFFECA00),
    tertiary: Color(0xFFD36328),
  ),
  AppTheme(
    id: 'plains_wanderer',
    name: 'Plains-wanderer',
    icon: Icons.terrain,
    primary: Color(0xFFEDD8C5),
    secondary: Color(0xFFE7AA01),
    tertiary: Color(0xFFD09A5E),
  ),
  AppTheme(
    id: 'bee_eater',
    name: 'Rainbow Bee-eater',
    icon: Icons.flight,
    primary: Color(0xFF00346E),
    secondary: Color(0xFFEDD03E),
    tertiary: Color(0xFF6D8600),
  ),
  AppTheme(
    id: 'rose_crowned_fruit_dove',
    name: 'Rose-crowned Fruit Dove',
    icon: Icons.local_florist,
    primary: Color(0xFFBD338F),
    secondary: Color(0xFFEB8252),
    tertiary: Color(0xFF8FA33F),
  ),
  AppTheme(
    id: 'eastern_rosella',
    name: 'Eastern Rosella',
    icon: Icons.park,
    primary: Color(0xFF2F533C),
    secondary: Color(0xFFF4C623),
    tertiary: Color(0xFF2F7AB9),
  ),
  AppTheme(
    id: 'oriole',
    name: 'Olivaceous Oriole',
    icon: Icons.wb_sunny,
    primary: Color(0xFFB8A53F),
    secondary: Color(0xFFA29EB8),
    tertiary: Color(0xFFBB5645),
  ),
  AppTheme(
    id: 'princess_parrot',
    name: 'Princess Parrot',
    icon: Icons.pets,
    primary: Color(0xFF7090C9),
    secondary: Color(0xFF6EB245),
    tertiary: Color(0xFFCF2236),
  ),
  AppTheme(
    id: 'superb_fairy_wren',
    name: 'Superb Fairy-wren',
    icon: Icons.blur_on,
    primary: Color(0xFFB03F05),
    secondary: Color(0xFFAA7853),
    tertiary: Color(0xFF4F3321),
  ),
  AppTheme(
    id: 'cassowary',
    name: 'Cassowary',
    icon: Icons.landscape,
    primary: Color(0xFF0169C4),
    secondary: Color(0xFFBDA14D),
    tertiary: Color(0xFFD5114E),
  ),
  AppTheme(
    id: 'yellow_robin',
    name: 'Eastern Yellow Robin',
    icon: Icons.light_mode,
    primary: Color(0xFF979EB9),
    secondary: Color(0xFFE19E00),
    tertiary: Color(0xFF85773A),
  ),
  AppTheme(
    id: 'galah',
    name: 'Galah',
    icon: Icons.favorite,
    primary: Color(0xFFD05478),
    secondary: Color(0xFFE9A7BB),
    tertiary: Color(0xFF4C5766),
  ),
  AppTheme(
    id: 'blue_winged_kookaburra',
    name: 'Blue-winged Kookaburra',
    icon: Icons.thunderstorm,
    primary: Color(0xFFAD8D9F),
    secondary: Color(0xFF0B7595),
    tertiary: Color(0xFFB5EFFB),
  ),
];
