import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/main_shell.dart';
import 'theme/app_themes.dart';
import 'services/database_service.dart';
import 'providers/theme_provider.dart';
import 'providers/font_provider.dart';
import 'providers/prefs_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Desktop-only app: SQLite goes through the FFI factory everywhere.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final prefs = await SharedPreferences.getInstance();
  // Apply the saved data-source path before the first query runs.
  final savedPath = prefs.getString('dbPath');
  if (savedPath != null && savedPath.isNotEmpty) {
    DatabaseService.overridePath = savedPath;
  }
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ExpensesApp(),
    ),
  );
}

class ExpensesApp extends ConsumerWidget {
  const ExpensesApp({super.key});

  // Scales every text style by [scale] while leaving the font family alone.
  TextTheme _scale(TextTheme base, double scale) {
    TextStyle? s(TextStyle? st, double fallback) =>
        st?.copyWith(fontSize: (st.fontSize ?? fallback) * scale);
    return base.copyWith(
      displayLarge: s(base.displayLarge, 57),
      displayMedium: s(base.displayMedium, 45),
      displaySmall: s(base.displaySmall, 36),
      headlineLarge: s(base.headlineLarge, 32),
      headlineMedium: s(base.headlineMedium, 28),
      headlineSmall: s(base.headlineSmall, 24),
      titleLarge: s(base.titleLarge, 22),
      titleMedium: s(base.titleMedium, 16),
      titleSmall: s(base.titleSmall, 14),
      bodyLarge: s(base.bodyLarge, 16),
      bodyMedium: s(base.bodyMedium, 14),
      bodySmall: s(base.bodySmall, 12),
      labelLarge: s(base.labelLarge, 14),
      labelMedium: s(base.labelMedium, 12),
      labelSmall: s(base.labelSmall, 11),
    );
  }

  // Applies the chosen Google Font (loaded on demand) to a scaled text theme.
  // 'System Default' keeps the platform font; an unknown family falls back to
  // it rather than throwing.
  TextTheme _applyFont(TextTheme base, String font, double scale) {
    final scaled = _scale(base, scale);
    if (font == 'System Default') return scaled;
    try {
      return GoogleFonts.getTextTheme(font, scaled);
    } catch (_) {
      return scaled;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIndex = ref.watch(themeIndexProvider);
    final themeMode = ref.watch(themeModeProvider);
    final variant = ref.watch(schemeVariantProvider);
    final font = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final t = appThemes[themeIndex];

    final scale = fontSize / 13.0;

    final light = t.themeData(Brightness.light, variant: variant);
    final dark = t.themeData(Brightness.dark, variant: variant);

    return MaterialApp(
      title: 'Expenses Dashboard',
      debugShowCheckedModeBanner: false,
      theme: light.copyWith(
        textTheme: _applyFont(light.textTheme, font, scale),
      ),
      darkTheme: dark.copyWith(
        textTheme: _applyFont(dark.textTheme, font, scale),
      ),
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}
