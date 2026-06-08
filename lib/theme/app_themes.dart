import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final ThemeData light;
  final ThemeData? dark;
  final IconData icon;

  const AppTheme({
    required this.name,
    required this.light,
    this.dark,
    required this.icon,
  });
}

const _black = Color(0xFF1A1A1A);
const _white = Color(0xFFF5F0E8);
const _neoBg = Color(0xFFF5F0E8);
const _neoRed = Color(0xFFE53935);
const _neoBlue = Color(0xFF1E88E5);

ThemeData _neoBrutalismLight() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: _black,
      onPrimary: _white,
      secondary: _neoRed,
      onSecondary: _white,
      tertiary: _neoBlue,
      onTertiary: _white,
      error: _neoRed,
      onError: _white,
      surface: _white,
      onSurface: _black,
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF8F6F2),
      surfaceContainerHigh: const Color(0xFFEDE8E0),
      outline: _black.withValues(alpha: 0.3),
      outlineVariant: _black.withValues(alpha: 0.15),
    ),
    scaffoldBackgroundColor: _neoBg,
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: Border.all(color: _black, width: 2.5),
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: AppBarThemeData(
      elevation: 0,
      backgroundColor: _black,
      foregroundColor: _white,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: _black.withValues(alpha: 0.3),
      thickness: 1.5,
      space: 0,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: _black.withValues(alpha: 0.1),
      labelType: NavigationRailLabelType.all,
      unselectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: _black,
      ),
      selectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: _black,
      ),
      unselectedIconTheme: const IconThemeData(color: _black, size: 22),
      selectedIconTheme: const IconThemeData(color: _black, size: 26),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _black),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _black),
      titleSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black),
      bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: _black),
      bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: _black),
      bodySmall: TextStyle(fontWeight: FontWeight.w500, color: _black),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _black),
      labelSmall: TextStyle(fontWeight: FontWeight.w500, color: _black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _black, width: 2.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _black, width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _neoBlue, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: _black),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _black,
        foregroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: _black,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: const BorderSide(color: _black, width: 2),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _black),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerColor: _black.withValues(alpha: 0.2),
    searchBarTheme: SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(Colors.white),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _black, width: 2.5),
        ),
      ),
    ),
    searchViewTheme: SearchViewThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _black, width: 2),
      ),
    ),
  );
}

ThemeData _neoBrutalismDark() {
  return _neoBrutalismLight().copyWith(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _black,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: _white,
      onPrimary: _black,
      secondary: _neoRed,
      onSecondary: _white,
      tertiary: _neoBlue,
      onTertiary: _white,
      error: _neoRed,
      onError: _white,
      surface: _black,
      onSurface: _white,
      surfaceContainerLowest: const Color(0xFF0A0A0A),
      surfaceContainerLow: const Color(0xFF1F1F1F),
      surfaceContainerHigh: const Color(0xFF2A2A2A),
      outline: Colors.white.withValues(alpha: 0.3),
      outlineVariant: Colors.white.withValues(alpha: 0.15),
    ),
    appBarTheme: AppBarThemeData(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _black,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: Border.all(color: Colors.white, width: 2.5),
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      indicatorColor: Colors.white.withValues(alpha: 0.15),
      unselectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: Colors.white70,
      ),
      selectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        color: Colors.white,
      ),
      unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 22),
      selectedIconTheme: const IconThemeData(color: Colors.white, size: 26),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white54, width: 2.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white54, width: 2.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _neoBlue, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        shadowColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    dividerColor: Colors.white.withValues(alpha: 0.2),
    searchBarTheme: SearchBarThemeData(
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white54, width: 2.5),
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
  final surfaceTint = colors.last.withValues(alpha: 0.03);

  return AppTheme(
    name: name,
    icon: icon,
    light: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        secondary: secondary,
        tertiary: tertiary,
        brightness: Brightness.light,
        surface: surfaceTint,
      ),
      brightness: Brightness.light,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: seed.withValues(alpha: 0.2), width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: seed,
        foregroundColor: seed.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: seed.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: seed.withValues(alpha: 0.15),
        labelType: NavigationRailLabelType.all,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: seed.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
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
    name: 'Neo Brutalism',
    icon: Icons.bolt,
    light: _neoBrutalismLight(),
    dark: _neoBrutalismDark(),
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
