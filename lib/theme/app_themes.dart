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

  /// [variant] controls how strongly the seed colours are expressed in the
  /// derived scheme (tonalSpot = calm default, vibrant/expressive = more
  /// chroma in containers and surfaces).
  ThemeData themeData(Brightness brightness,
      {DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      brightness: brightness,
      dynamicSchemeVariant: variant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // A softly tinted canvas one step above the base surface, so cards and
      // panels (surfaceContainerLowest) visibly lift off the background.
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
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
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(6),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// The selectable themes: each one is drawn from the plumage of a real bird,
/// using the hand-picked palettes from ryandam.net/demos/feathers_palettes.
/// The seed colours come from the bird's most striking feathers and the chart
/// palette from the rest of its colouring (very pale or near-black swatches
/// are kept out of the chart set so data stays legible in both modes).
const appThemes = <AppTheme>[
  // #feca00 #d36328 #cb0300 #b4b9b3 #424847 #000100
  AppTheme(
    id: 'spotted_pardalote',
    name: 'Spotted Pardalote',
    icon: Icons.blur_on,
    primary: Color(0xFFD36328),
    secondary: Color(0xFFFECA00),
    tertiary: Color(0xFFCB0300),
    chartColors: [
      Color(0xFFFECA00),
      Color(0xFFD36328),
      Color(0xFFCB0300),
      Color(0xFFB4B9B3),
      Color(0xFF424847),
    ],
  ),
  // #edd8c5 #d09a5e #e7aa01 #ac570f #73481b #442c0e #0d0403
  AppTheme(
    id: 'plains_wanderer',
    name: 'Plains-wanderer',
    icon: Icons.landscape,
    primary: Color(0xFFAC570F),
    secondary: Color(0xFFE7AA01),
    tertiary: Color(0xFF73481B),
    chartColors: [
      Color(0xFFE7AA01),
      Color(0xFFAC570F),
      Color(0xFFD09A5E),
      Color(0xFF73481B),
      Color(0xFF442C0E),
    ],
  ),
  // #00346E #007CBF #06ABDF #EDD03E #F5A200 #6D8600 #424D0C
  AppTheme(
    id: 'bee_eater',
    name: 'Rainbow Bee-eater',
    icon: Icons.emoji_nature,
    primary: Color(0xFF007CBF),
    secondary: Color(0xFF06ABDF),
    tertiary: Color(0xFFF5A200),
    chartColors: [
      Color(0xFF007CBF),
      Color(0xFFF5A200),
      Color(0xFF06ABDF),
      Color(0xFFEDD03E),
      Color(0xFF6D8600),
      Color(0xFF00346E),
    ],
  ),
  // #BD338F #EB8252 #F5DC83 #CDD4DC #8098A2 #8FA33F #5F7929 #014820
  AppTheme(
    id: 'rose_crowned_fruit_dove',
    name: 'Rose-crowned Fruit-Dove',
    icon: Icons.local_florist,
    primary: Color(0xFFBD338F),
    secondary: Color(0xFF5F7929),
    tertiary: Color(0xFFEB8252),
    chartColors: [
      Color(0xFFBD338F),
      Color(0xFFEB8252),
      Color(0xFF8FA33F),
      Color(0xFF8098A2),
      Color(0xFF014820),
      Color(0xFFF5DC83),
    ],
  ),
  // #cd3122 #f4c623 #bee183 #6c905e #2f533c #b8c9dc #2f7ab9
  AppTheme(
    id: 'eastern_rosella',
    name: 'Eastern Rosella',
    icon: Icons.palette,
    primary: Color(0xFFCD3122),
    secondary: Color(0xFF2F7AB9),
    tertiary: Color(0xFFF4C623),
    chartColors: [
      Color(0xFFCD3122),
      Color(0xFF2F7AB9),
      Color(0xFFF4C623),
      Color(0xFF6C905E),
      Color(0xFFBEE183),
      Color(0xFF2F533C),
    ],
  ),
  // #8a3223 #bb5645 #d97878 #e2aba0 #d0cfe9 #a29eb8 #6c6b75 #b8a53f #93862a #4d4019
  AppTheme(
    id: 'oriole',
    name: 'Oriole',
    icon: Icons.music_note,
    primary: Color(0xFFBB5645),
    secondary: Color(0xFF93862A),
    tertiary: Color(0xFFA29EB8),
    chartColors: [
      Color(0xFFBB5645),
      Color(0xFFB8A53F),
      Color(0xFFA29EB8),
      Color(0xFF6C6B75),
      Color(0xFFD97878),
      Color(0xFF4D4019),
    ],
  ),
  // #7090c9 #8cb3de #afbe9f #616020 #6eb245 #214917 #cf2236 #d683ad
  AppTheme(
    id: 'princess_parrot',
    name: 'Princess Parrot',
    icon: Icons.auto_awesome,
    primary: Color(0xFF7090C9),
    secondary: Color(0xFF6EB245),
    tertiary: Color(0xFFD683AD),
    chartColors: [
      Color(0xFF7090C9),
      Color(0xFF6EB245),
      Color(0xFFD683AD),
      Color(0xFFCF2236),
      Color(0xFF8CB3DE),
      Color(0xFF214917),
    ],
  ),
  // #4F3321 #AA7853 #D9C4A7 #B03F05 #020503
  AppTheme(
    id: 'superb_fairy_wren',
    name: 'Superb Fairy-wren',
    icon: Icons.flutter_dash,
    primary: Color(0xFFB03F05),
    secondary: Color(0xFFAA7853),
    tertiary: Color(0xFF4F3321),
    chartColors: [
      Color(0xFFB03F05),
      Color(0xFFAA7853),
      Color(0xFF4F3321),
      Color(0xFFD9C4A7),
    ],
  ),
  // #BDA14D #3EBCB6 #0169C4 #153460 #D5114E #A56EB6 #4B1C57 #09090C
  AppTheme(
    id: 'cassowary',
    name: 'Cassowary',
    icon: Icons.forest,
    primary: Color(0xFF0169C4),
    secondary: Color(0xFF3EBCB6),
    tertiary: Color(0xFFD5114E),
    chartColors: [
      Color(0xFF0169C4),
      Color(0xFF3EBCB6),
      Color(0xFFD5114E),
      Color(0xFFBDA14D),
      Color(0xFFA56EB6),
      Color(0xFF153460),
    ],
  ),
  // #E19E00 #FBEB5B #85773A #979EB9 #727B98 #454B56 #201B1E
  AppTheme(
    id: 'yellow_robin',
    name: 'Yellow Robin',
    icon: Icons.wb_sunny,
    primary: Color(0xFFE19E00),
    secondary: Color(0xFF727B98),
    tertiary: Color(0xFF85773A),
    chartColors: [
      Color(0xFFE19E00),
      Color(0xFF727B98),
      Color(0xFF85773A),
      Color(0xFFFBEB5B),
      Color(0xFF979EB9),
      Color(0xFF454B56),
    ],
  ),
  // #FFD2CF #E9A7BB #D05478 #AAB9CC #8390A2 #4C5766
  AppTheme(
    id: 'galah',
    name: 'Galah',
    icon: Icons.favorite,
    primary: Color(0xFFD05478),
    secondary: Color(0xFF8390A2),
    tertiary: Color(0xFFE9A7BB),
    chartColors: [
      Color(0xFFD05478),
      Color(0xFF8390A2),
      Color(0xFFE9A7BB),
      Color(0xFF4C5766),
      Color(0xFFAAB9CC),
    ],
  ),
  // #b5effb #0b7595 #02407c #06213a #c45829 #9C4620 #622C14 #d4d8e3 #b8bcd8 #ad8d9f #725f77
  AppTheme(
    id: 'blue_winged_kookaburra',
    name: 'Blue-winged Kookaburra',
    icon: Icons.air,
    primary: Color(0xFF0B7595),
    secondary: Color(0xFFC45829),
    tertiary: Color(0xFF725F77),
    chartColors: [
      Color(0xFF0B7595),
      Color(0xFFC45829),
      Color(0xFF02407C),
      Color(0xFFAD8D9F),
      Color(0xFF725F77),
      Color(0xFFB8BCD8),
    ],
  ),
];
