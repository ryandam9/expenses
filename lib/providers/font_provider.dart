import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontFamilyNotifier extends Notifier<String> {
  @override
  String build() => 'Google Sans';

  void select(String family) => state = family;
}

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() => 13;

  void setSize(double size) => state = size;
}

final fontFamilyProvider = NotifierProvider<FontFamilyNotifier, String>(FontFamilyNotifier.new);
final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(FontSizeNotifier.new);

const systemFonts = [
  'Google Sans',
  'System Default',
  'Roboto',
  'Inter',
  'Space Grotesk',
  'JetBrains Mono',
];
