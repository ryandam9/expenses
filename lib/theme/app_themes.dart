import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final ThemeData light;
  final ThemeData? dark;
  final IconData icon;

  /// The raw feather palette behind this theme. Used to colour charts and
  /// accents so visualisations share the theme's identity instead of a
  /// generic, off-theme set of colours.
  final List<Color> palette;

  const AppTheme({
    required this.name,
    required this.light,
    this.dark,
    required this.icon,
    this.palette = const [],
  });
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

// --- Studio: the default, hand-tuned theme ----------------------------------
//
// A calm, modern dashboard look built on standard Material 3. The accent is a
// muted indigo; surfaces are clean white cards floating over a cool, barely
// tinted background. Corners are generously rounded, borders are hairline, and
// shadows are soft and low — the opposite of the old brutalist look. Designed
// so financial data reads clearly without the chrome competing for attention.
const _studioIndigo = Color(0xFF4F5BD5); // primary accent
const _studioInk = Color(0xFF1B1C2A); // near-black text
const _studioBg = Color(0xFFF4F5FA); // cool off-white canvas
const _studioBorder = Color(0xFFE6E8F0); // hairline card border

ThemeData _studioLight() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _studioIndigo,
    brightness: Brightness.light,
  ).copyWith(
    primary: _studioIndigo,
    onSurface: _studioInk,
    surface: Colors.white,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: _studioBg,
    surfaceContainerHigh: const Color(0xFFEFF1F8),
    outline: const Color(0xFFC9CCDA),
    outlineVariant: _studioBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: _studioBg,
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shadowColor: _studioInk.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _studioBorder, width: 1),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: const AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _studioInk,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 19,
        color: _studioInk,
        letterSpacing: -0.2,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _studioBorder,
      thickness: 1,
      space: 1,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: _studioIndigo.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelType: NavigationRailLabelType.all,
      unselectedLabelTextStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: _studioInk.withValues(alpha: 0.55),
      ),
      selectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: _studioIndigo,
      ),
      unselectedIconTheme: IconThemeData(
        color: _studioInk.withValues(alpha: 0.55),
        size: 22,
      ),
      selectedIconTheme: const IconThemeData(color: _studioIndigo, size: 24),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: _studioInk, letterSpacing: -0.3),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _studioInk, letterSpacing: -0.1),
      titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _studioInk),
      bodyLarge: TextStyle(fontWeight: FontWeight.w400, color: _studioInk),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: _studioInk),
      bodySmall: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF5B5D6E)),
      labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _studioInk),
      labelSmall: TextStyle(fontWeight: FontWeight.w500, color: _studioInk),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _studioBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _studioBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _studioBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _studioIndigo, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        color: _studioInk.withValues(alpha: 0.7),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _studioIndigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _studioBg,
      side: const BorderSide(color: _studioBorder, width: 1),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: _studioInk),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerColor: _studioBorder,
    searchBarTheme: SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(_studioBg),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _studioBorder, width: 1),
        ),
      ),
    ),
    searchViewTheme: SearchViewThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _studioBorder, width: 1),
      ),
    ),
  );
}

ThemeData _studioDark() {
  const darkBg = Color(0xFF14151C);
  const darkSurface = Color(0xFF1D1F29);
  const darkBorder = Color(0xFF2C2F3C);
  const darkText = Color(0xFFE8E9F0);
  const accent = Color(0xFF8B95F2);

  final scheme = ColorScheme.fromSeed(
    seedColor: _studioIndigo,
    brightness: Brightness.dark,
  ).copyWith(
    primary: accent,
    onPrimary: const Color(0xFF111219),
    onSurface: darkText,
    surface: darkSurface,
    surfaceContainerLowest: darkBg,
    surfaceContainerLow: darkSurface,
    surfaceContainerHigh: const Color(0xFF252835),
    outline: const Color(0xFF3A3D4C),
    outlineVariant: darkBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: const AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: darkBg,
      foregroundColor: darkText,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 19,
        color: darkText,
        letterSpacing: -0.2,
      ),
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 1),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: darkSurface,
      indicatorColor: accent.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelType: NavigationRailLabelType.all,
      unselectedLabelTextStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: darkText.withValues(alpha: 0.55),
      ),
      selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: accent),
      unselectedIconTheme: IconThemeData(color: darkText.withValues(alpha: 0.55), size: 22),
      selectedIconTheme: const IconThemeData(color: accent, size: 24),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: darkText, letterSpacing: -0.3),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: darkText, letterSpacing: -0.1),
      titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: darkText),
      bodyLarge: TextStyle(fontWeight: FontWeight.w400, color: darkText),
      bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: darkText),
      bodySmall: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF9A9DB0)),
      labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: darkText),
      labelSmall: TextStyle(fontWeight: FontWeight.w500, color: darkText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252835),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
      labelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: darkText.withValues(alpha: 0.7)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: const Color(0xFF111219),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF252835),
      side: const BorderSide(color: darkBorder, width: 1),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: darkText),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerColor: darkBorder,
    searchBarTheme: SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(const Color(0xFF252835)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
    ),
  );
}

AppTheme _birdTheme({
  required String name,
  required IconData icon,
  required List<int> palette,
}) {
  final colors = palette.map((c) => Color(c)).toList();
  final seed = colors[0];
  final secondary = colors.length > 2 ? colors[2] : colors.last;
  final tertiary = colors.length > 3 ? colors[3] : colors[colors.length ~/ 2];

  // A pick that is dark enough to read white text on top of it — used for the
  // app bar and navigation accents so the palette's identity comes through
  // strongly rather than being washed out by Material's tonal mapping.
  final accent = colors.firstWhere(
    (c) => c.computeLuminance() < 0.42,
    orElse: () => seed,
  );
  final onAccent = accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  // Backgrounds stay light: a barely-there wash of the seed over white keeps
  // the surface bright while still feeling part of the theme.
  final bg = Color.alphaBlend(seed.withValues(alpha: 0.05), const Color(0xFFFFFFFF));

  return AppTheme(
    name: name,
    icon: icon,
    palette: colors,
    light: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        secondary: secondary,
        tertiary: tertiary,
        brightness: Brightness.light,
      ).copyWith(
        surface: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: bg,
      ),
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: seed.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: seed.withValues(alpha: 0.16), width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: onAccent,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: accent.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: accent, size: 26),
        selectedLabelTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: accent,
        ),
        labelType: NavigationRailLabelType.all,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: seed.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: seed.withValues(alpha: 0.3)),
          ),
        ),
      ),
    ),
    dark: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        secondary: secondary,
        tertiary: tertiary,
        brightness: Brightness.dark,
      ),
      brightness: Brightness.dark,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: secondary.withValues(alpha: 0.3), width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.last,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: seed.withValues(alpha: 0.2),
        labelType: NavigationRailLabelType.all,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: secondary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: secondary.withValues(alpha: 0.3)),
          ),
        ),
      ),
    ),
  );
}

final appThemes = [
  AppTheme(
    name: 'Studio',
    icon: Icons.dashboard_rounded,
    light: _studioLight(),
    dark: _studioDark(),
    palette: const [
      _studioIndigo,
      Color(0xFF2BB6A3), // teal
      Color(0xFFF59E42), // amber
      Color(0xFFE5689A), // rose
      Color(0xFF6CACE4), // sky
      Color(0xFF8B6FD6), // violet
      Color(0xFF59C26B), // green
      Color(0xFFE2645C), // coral
    ],
  ),
  _birdTheme(
    name: 'Spotted Pardalote',
    icon: Icons.emoji_nature,
    palette: [0xfeca00, 0xd36328, 0xcb0300, 0xb4b9b3, 0x424847, 0x000100],
  ),
  _birdTheme(
    name: 'Plains Wanderer',
    icon: Icons.terrain,
    palette: [0xd09a5e, 0xe7aa01, 0xac570f, 0x73481b, 0x442c0e, 0xedd8c5, 0x0d0403],
  ),
  _birdTheme(
    name: 'Bee Eater',
    icon: Icons.flight,
    palette: [0x007CBF, 0x00346E, 0x06ABDF, 0xEDD03E, 0xF5A200, 0x6D8600, 0x424D0C],
  ),
  _birdTheme(
    name: 'Rose-crowned Fruit Dove',
    icon: Icons.local_florist,
    palette: [0xBD338F, 0xEB8252, 0xF5DC83, 0xCDD4DC, 0x8098A2, 0x8FA33F, 0x5F7929, 0x014820],
  ),
  _birdTheme(
    name: 'Eastern Rosella',
    icon: Icons.park,
    palette: [0xcd3122, 0xf4c623, 0xbee183, 0x6c905e, 0x2f533c, 0xb8c9dc, 0x2f7ab9],
  ),
  _birdTheme(
    name: 'Oriole',
    icon: Icons.wb_sunny,
    palette: [0xd97878, 0xbb5645, 0x8a3223, 0xe2aba0, 0xd0cfe9, 0xa29eb8, 0x6c6b75, 0xb8a53f],
  ),
  _birdTheme(
    name: 'Princess Parrot',
    icon: Icons.pets,
    palette: [0x7090c9, 0x8cb3de, 0xafbe9f, 0x616020, 0x6eb245, 0x214917, 0xcf2236, 0xd683ad],
  ),
  _birdTheme(
    name: 'Superb Fairy-wren',
    icon: Icons.blur_on,
    palette: [0xAA7853, 0xD9C4A7, 0xB03F05, 0x4F3321, 0x020503],
  ),
  _birdTheme(
    name: 'Cassowary',
    icon: Icons.landscape,
    palette: [0xBDA14D, 0x3EBCB6, 0x0169C4, 0x153460, 0xD5114E, 0xA56EB6, 0x4B1C57, 0x09090C],
  ),
  _birdTheme(
    name: 'Yellow Robin',
    icon: Icons.light_mode,
    palette: [0xE19E00, 0xFBEB5B, 0x85773A, 0x979EB9, 0x727B98, 0x454B56, 0x201B1E],
  ),
  _birdTheme(
    name: 'Galah',
    icon: Icons.favorite,
    palette: [0xE9A7BB, 0xD05478, 0xFFD2CF, 0xAAB9CC, 0x8390A2, 0x4C5766],
  ),
  _birdTheme(
    name: 'Blue-winged Kookaburra',
    icon: Icons.thunderstorm,
    palette: [0x0b7595, 0x02407c, 0x06213a, 0xb5effb, 0xc45829, 0x9C4620, 0x622C14, 0xd4d8e3],
  ),
];
