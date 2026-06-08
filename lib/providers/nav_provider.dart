import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected destination in the app's navigation rail. Kept in a provider so it
/// survives a shell remount (e.g. when the theme changes).
class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final navIndexProvider =
    NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);
