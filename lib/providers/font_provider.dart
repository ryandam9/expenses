import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'prefs_provider.dart';

class FontFamilyNotifier extends Notifier<String> {
  @override
  String build() =>
      ref.read(sharedPreferencesProvider).getString('fontFamily') ?? 'Manrope';

  void select(String family) {
    state = family;
    ref.read(sharedPreferencesProvider).setString('fontFamily', family);
  }
}

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() =>
      ref.read(sharedPreferencesProvider).getDouble('fontSize') ?? 13;

  void setSize(double size) {
    state = size;
    ref.read(sharedPreferencesProvider).setDouble('fontSize', size);
  }
}

final fontFamilyProvider = NotifierProvider<FontFamilyNotifier, String>(FontFamilyNotifier.new);
final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(FontSizeNotifier.new);

/// Every font family the bundled google_fonts package can load (the entire
/// Google Fonts catalogue — Google Sans, Inter, Roboto, …) preceded by the
/// platform default. Fonts are fetched and cached on first use, so the list
/// costs nothing until a family is actually selected.
final List<String> systemFonts = [
  'System Default',
  ...GoogleFonts.asMap().keys,
];
