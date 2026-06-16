import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/main_shell.dart';
import 'theme/app_themes.dart';
import 'theme/typography.dart';
import 'services/database_service.dart';
import 'providers/theme_provider.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIndex = ref.watch(themeIndexProvider);
    final themeMode = ref.watch(themeModeProvider);
    final variant = ref.watch(schemeVariantProvider);
    final t = appThemes[themeIndex];

    final light = t.themeData(Brightness.light, variant: variant);
    final dark = t.themeData(Brightness.dark, variant: variant);

    return MaterialApp(
      title: 'Expenses Dashboard',
      debugShowCheckedModeBanner: false,
      theme: light.copyWith(textTheme: appTextTheme(light.textTheme)),
      darkTheme: dark.copyWith(textTheme: appTextTheme(dark.textTheme)),
      themeMode: themeMode,
      home: const MainShell(),
    );
  }
}
