import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the [SharedPreferences] instance. Overridden in `main()` once prefs
/// have loaded, so every other provider can read/write settings synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Bumped whenever the data source changes, so screens know to reload.
class DataReloadNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

final dataReloadProvider =
    NotifierProvider<DataReloadNotifier, int>(DataReloadNotifier.new);

/// The configured database path, persisted. An empty string means "not
/// configured yet" (the dashboard shows its first-run setup state).
class DbPathNotifier extends Notifier<String> {
  @override
  String build() => ref.read(sharedPreferencesProvider).getString('dbPath') ?? '';

  void set(String path) {
    final p = path.trim();
    state = p;
    ref.read(sharedPreferencesProvider).setString('dbPath', p);
  }
}

final dbPathProvider =
    NotifierProvider<DbPathNotifier, String>(DbPathNotifier.new);
