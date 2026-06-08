import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/main_shell.dart';
import 'theme/app_themes.dart';
import 'providers/theme_provider.dart';
import 'providers/font_provider.dart';

void main() {
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpensesApp()));
}

class ExpensesApp extends ConsumerWidget {
  const ExpensesApp({super.key});

  TextTheme _applyFont(TextTheme base, String? fontFamily, double scale) {
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.displayLarge?.fontSize ?? 57) * scale,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.displayMedium?.fontSize ?? 45) * scale,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.displaySmall?.fontSize ?? 36) * scale,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.headlineLarge?.fontSize ?? 32) * scale,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.headlineMedium?.fontSize ?? 28) * scale,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.headlineSmall?.fontSize ?? 24) * scale,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.titleLarge?.fontSize ?? 22) * scale,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.titleMedium?.fontSize ?? 16) * scale,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.titleSmall?.fontSize ?? 14) * scale,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.bodyLarge?.fontSize ?? 16) * scale,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.bodyMedium?.fontSize ?? 14) * scale,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.bodySmall?.fontSize ?? 12) * scale,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.labelLarge?.fontSize ?? 14) * scale,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.labelMedium?.fontSize ?? 12) * scale,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: fontFamily,
        fontSize: (base.labelSmall?.fontSize ?? 11) * scale,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIndex = ref.watch(themeIndexProvider);
    final themeMode = ref.watch(themeModeProvider);
    final font = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final t = appThemes[themeIndex];

    final fontFamily = font == 'System Default' ? null : font;
    final scale = fontSize / 13.0;

    final light = t.themeData(Brightness.light);
    final dark = t.themeData(Brightness.dark);

    return MaterialApp(
      title: 'Expenses Dashboard',
      debugShowCheckedModeBanner: false,
      theme: light.copyWith(
        textTheme: _applyFont(light.textTheme, fontFamily, scale),
      ),
      darkTheme: dark.copyWith(
        textTheme: _applyFont(dark.textTheme, fontFamily, scale),
      ),
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}
