import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefs_provider.dart';

/// Selected destination in the app's navigation rail. Kept in a provider so it
/// survives a shell remount (e.g. when the theme changes).
class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final navIndexProvider =
    NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);

/// Whether the sidebar is collapsed to icons only (labels hidden). Persisted so
/// the choice survives restarts.
class SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool('sidebarCollapsed') ?? false;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool('sidebarCollapsed', state);
  }
}

final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedNotifier, bool>(
        SidebarCollapsedNotifier.new);

/// Free-text search shared between the global top-bar search field and the
/// Transactions screen, so typing in the header drives the table.
class GlobalSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final globalSearchProvider =
    NotifierProvider<GlobalSearchNotifier, String>(GlobalSearchNotifier.new);
