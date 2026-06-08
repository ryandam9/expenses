import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final themeIndexProvider = NotifierProvider<ThemeIndexNotifier, int>(ThemeIndexNotifier.new);

/// Light / dark / follow-system. Defaults to following the system, mirroring
/// the companion attendance-register app.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void select(ThemeMode mode) => state = mode;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
