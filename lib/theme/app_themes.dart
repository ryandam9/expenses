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

/// The selectable themes: each one is drawn from the plumage of a real bird —
/// the seed colours come from its most striking feathers and the six-colour
/// chart palette from the rest of its colouring, so picking a theme dresses
/// the whole dashboard in that bird's feathers.
const appThemes = <AppTheme>[
  // Blue head, orange-red breast, green wings, yellow nape, violet belly.
  AppTheme(
    id: 'lorikeet',
    name: 'Rainbow Lorikeet',
    icon: Icons.looks,
    primary: Color(0xFF2E5EAA),
    secondary: Color(0xFF43A047),
    tertiary: Color(0xFFF26419),
    chartColors: [
      Color(0xFF2E5EAA), // head blue
      Color(0xFFF26419), // breast orange
      Color(0xFF43A047), // wing green
      Color(0xFFF6AE2D), // nape yellow
      Color(0xFFD7263D), // breast red
      Color(0xFF7B4FA6), // belly violet
    ],
  ),
  // Deep azure back, teal sheen, warm orange chest over river-water blues.
  AppTheme(
    id: 'kingfisher',
    name: 'Azure Kingfisher',
    icon: Icons.waves,
    primary: Color(0xFF0F6BAE),
    secondary: Color(0xFF12A5BC),
    tertiary: Color(0xFFE98A33),
    chartColors: [
      Color(0xFF0F6BAE), // azure back
      Color(0xFFE98A33), // chest orange
      Color(0xFF12A5BC), // teal sheen
      Color(0xFF74B3CE), // wing shimmer
      Color(0xFFC75146), // rufous flank
      Color(0xFF134074), // deep water navy
    ],
  ),
  // Crimson body, violet-blue cheeks and wing edges, scalloped black back.
  AppTheme(
    id: 'rosella',
    name: 'Crimson Rosella',
    icon: Icons.local_florist,
    primary: Color(0xFFC2233B),
    secondary: Color(0xFF2A5CAA),
    tertiary: Color(0xFFE8647C),
    chartColors: [
      Color(0xFFC2233B), // crimson body
      Color(0xFF2A5CAA), // cheek blue
      Color(0xFFE8647C), // rose breast
      Color(0xFF64A6E8), // wing-edge blue
      Color(0xFFE9A115), // young bird olive-gold
      Color(0xFF4A4E69), // scalloped back
    ],
  ),
  // Purple chest, golden belly, green back, scarlet face, turquoise nape.
  AppTheme(
    id: 'gouldian',
    name: 'Gouldian Finch',
    icon: Icons.palette,
    primary: Color(0xFF6A3FA0),
    secondary: Color(0xFF19B3B1),
    tertiary: Color(0xFFF4C20D),
    chartColors: [
      Color(0xFF6A3FA0), // chest purple
      Color(0xFF19B3B1), // nape turquoise
      Color(0xFFF4C20D), // belly gold
      Color(0xFF3F9B42), // back green
      Color(0xFFD7263D), // face scarlet
      Color(0xFFE879B9), // pink-faced morph
    ],
  ),
  // Iridescent cobalt and sky blue over the soft fawn of the females.
  AppTheme(
    id: 'fairywren',
    name: 'Superb Fairywren',
    icon: Icons.flutter_dash,
    primary: Color(0xFF2356C5),
    secondary: Color(0xFF56B6E9),
    tertiary: Color(0xFFB9824F),
    chartColors: [
      Color(0xFF2356C5), // crown cobalt
      Color(0xFF56B6E9), // cheek sky blue
      Color(0xFFB9824F), // female fawn
      Color(0xFF5B6377), // grey-brown wing
      Color(0xFFE9A115), // sunlit grass
      Color(0xFF15B097), // eucalypt teal
    ],
  ),
  // Rose-pink chest under dove-grey wings and a pale crest.
  AppTheme(
    id: 'galah',
    name: 'Galah',
    icon: Icons.favorite,
    primary: Color(0xFFD94F70),
    secondary: Color(0xFF7E8287),
    tertiary: Color(0xFFF2A0B2),
    chartColors: [
      Color(0xFFD94F70), // chest rose
      Color(0xFF7E8287), // wing grey
      Color(0xFFF2A0B2), // crest blush
      Color(0xFF8E4162), // deep plum
      Color(0xFF5F9EA0), // dusty outback teal
      Color(0xFF3A3E47), // flight-feather charcoal
    ],
  ),
  // Earthy browns and buff with the surprise blue flash on the wing.
  AppTheme(
    id: 'kookaburra',
    name: 'Kookaburra',
    icon: Icons.forest,
    primary: Color(0xFF4F7CAC),
    secondary: Color(0xFF8B5E3C),
    tertiary: Color(0xFFC49A6C),
    chartColors: [
      Color(0xFF4F7CAC), // wing-flash blue
      Color(0xFF8B5E3C), // back brown
      Color(0xFFC49A6C), // buff breast
      Color(0xFFB0413E), // rufous tail
      Color(0xFF7C9A6D), // gum-leaf sage
      Color(0xFF2F3640), // eye-stripe charcoal
    ],
  ),
  // Teal neck, royal train, emerald coverts and golden eyespots.
  AppTheme(
    id: 'peacock',
    name: 'Peacock',
    icon: Icons.filter_vintage,
    primary: Color(0xFF0E7C86),
    secondary: Color(0xFF1F4690),
    tertiary: Color(0xFFD4A017),
    chartColors: [
      Color(0xFF0E7C86), // neck teal
      Color(0xFF1F4690), // train royal blue
      Color(0xFFD4A017), // eyespot gold
      Color(0xFF2E8B57), // covert emerald
      Color(0xFF7C3AED), // iridescent violet
      Color(0xFFB5651D), // eyespot copper
    ],
  ),
  // Pink and coral plumage, sandy gold, lagoon water and the black bill tip.
  AppTheme(
    id: 'flamingo',
    name: 'Flamingo',
    icon: Icons.spa,
    primary: Color(0xFFE85C8A),
    secondary: Color(0xFFF08A5D),
    tertiary: Color(0xFFE8B86D),
    chartColors: [
      Color(0xFFE85C8A), // body pink
      Color(0xFFF08A5D), // wing coral
      Color(0xFFE8B86D), // sandy gold
      Color(0xFF5FB49C), // lagoon teal
      Color(0xFFB14AED), // sunset orchid
      Color(0xFF2B2D42), // bill-tip black
    ],
  ),
];
