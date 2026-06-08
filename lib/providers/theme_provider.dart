import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final themeIndexProvider = NotifierProvider<ThemeIndexNotifier, int>(ThemeIndexNotifier.new);
