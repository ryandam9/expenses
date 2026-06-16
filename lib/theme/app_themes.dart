import 'package:flutter/material.dart';
import 'brutalism.dart';

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

  /// [variant] controls how strongly the seed colours are expressed in the
  /// derived scheme (tonalSpot = calm default, vibrant/expressive = more
  /// chroma in containers and surfaces).
  ThemeData themeData(
    Brightness brightness, {
    DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot,
  }) {
    // The brand colours are tuned to read on light surfaces (several themes
    // deliberately lead with a dark primary), so they're pinned only in light
    // mode. In dark mode we seed from the theme's signature chart colour and
    // let ColorScheme.fromSeed derive light primary/secondary/tertiary tones,
    // so accent-coloured text and icons stay legible on dark surfaces.
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: isLight ? primary : chartColors.first,
      primary: isLight ? primary : null,
      secondary: isLight ? secondary : null,
      tertiary: isLight ? tertiary : null,
      brightness: brightness,
      dynamicSchemeVariant: variant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 19,
          color: scheme.onSurface,
          letterSpacing: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: brutalLine(scheme), width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: brutalLine(scheme), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: brutalLine(scheme), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: brutalLine(scheme), width: 1),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: brutalLine(scheme), width: 1),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: brutalLine(scheme), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: brutalLine(scheme), width: 1),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            scheme.surfaceContainerLowest,
          ),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(8),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

/// The selectable themes, built from six bold colour pairs (a vivid accent and
/// a high-contrast partner). Each pair drives a Material scheme plus a six
/// colour, mutually distinct chart palette. For pairs whose vivid colour is too
/// light to read as foreground on light surfaces (lime, yellow, mint, pale
/// teal), the darker partner leads as [primary] and the vivid colour carries
/// the accent through [secondary] and the charts.
const appThemes = <AppTheme>[
  // #6260FF / #E4E4FF
  AppTheme(
    id: 'periwinkle',
    name: 'Periwinkle',
    icon: Icons.bubble_chart_rounded,
    primary: Color(0xFF6260FF),
    secondary: Color(0xFF34E0A1),
    tertiary: Color(0xFFFF6584),
    chartColors: [
      Color(0xFF6260FF),
      Color(0xFF34E0A1),
      Color(0xFFFCDB32),
      Color(0xFFFF6584),
      Color(0xFF3447AA),
      Color(0xFF9FE870),
    ],
  ),
  // #9FE870 / #163300
  AppTheme(
    id: 'lime',
    name: 'Lime',
    icon: Icons.eco_rounded,
    primary: Color(0xFF163300),
    secondary: Color(0xFF9FE870),
    tertiary: Color(0xFF34E0A1),
    chartColors: [
      Color(0xFF163300),
      Color(0xFF9FE870),
      Color(0xFF34E0A1),
      Color(0xFFFCDB32),
      Color(0xFF3447AA),
      Color(0xFF6260FF),
    ],
  ),
  // #BDD9D7 / #03363D
  AppTheme(
    id: 'mist',
    name: 'Mist',
    icon: Icons.waves_rounded,
    primary: Color(0xFF03363D),
    secondary: Color(0xFF34E0A1),
    tertiary: Color(0xFFBDD9D7),
    chartColors: [
      Color(0xFF03363D),
      Color(0xFF34E0A1),
      Color(0xFFBDD9D7),
      Color(0xFFFCDB32),
      Color(0xFF6260FF),
      Color(0xFFFF6584),
    ],
  ),
  // #3447AA / #FBEAEB
  AppTheme(
    id: 'cobalt',
    name: 'Cobalt',
    icon: Icons.bolt_rounded,
    primary: Color(0xFF3447AA),
    secondary: Color(0xFFFF6584),
    tertiary: Color(0xFFFCDB32),
    chartColors: [
      Color(0xFF3447AA),
      Color(0xFFFF6584),
      Color(0xFFFCDB32),
      Color(0xFF34E0A1),
      Color(0xFF6260FF),
      Color(0xFF9FE870),
    ],
  ),
  // #FCDB32 / #141D38
  AppTheme(
    id: 'sunbeam',
    name: 'Sunbeam',
    icon: Icons.wb_sunny_rounded,
    primary: Color(0xFF141D38),
    secondary: Color(0xFFFCDB32),
    tertiary: Color(0xFF6260FF),
    chartColors: [
      Color(0xFF141D38),
      Color(0xFFFCDB32),
      Color(0xFF34E0A1),
      Color(0xFF6260FF),
      Color(0xFFFF6584),
      Color(0xFF9FE870),
    ],
  ),
  // #34E0A1 / #000000
  AppTheme(
    id: 'mint',
    name: 'Mint',
    icon: Icons.spa_rounded,
    primary: Color(0xFF141414),
    secondary: Color(0xFF34E0A1),
    tertiary: Color(0xFF6260FF),
    chartColors: [
      Color(0xFF34E0A1),
      Color(0xFF141D38),
      Color(0xFFFCDB32),
      Color(0xFF6260FF),
      Color(0xFFFF6584),
      Color(0xFF3447AA),
    ],
  ),
];
