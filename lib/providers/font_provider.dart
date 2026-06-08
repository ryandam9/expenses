import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontFamilyNotifier extends Notifier<String> {
  @override
  String build() => 'Inter';

  void select(String family) => state = family;
}

class FontSizeNotifier extends Notifier<double> {
  @override
  double build() => 13;

  void setSize(double size) => state = size;
}

final fontFamilyProvider = NotifierProvider<FontFamilyNotifier, String>(FontFamilyNotifier.new);
final fontSizeProvider = NotifierProvider<FontSizeNotifier, double>(FontSizeNotifier.new);

/// A curated set of Google Fonts (plus the platform default). Each name is a
/// valid Google Fonts family so it can be loaded on demand via
/// `GoogleFonts.getTextTheme`. Grouped roughly sans → serif → monospace.
const systemFonts = [
  'System Default',
  // Sans-serif
  'Inter',
  'Roboto',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Poppins',
  'Nunito',
  'Nunito Sans',
  'Work Sans',
  'Source Sans 3',
  'Raleway',
  'Rubik',
  'Manrope',
  'DM Sans',
  'IBM Plex Sans',
  'Karla',
  'Mulish',
  'Noto Sans',
  'PT Sans',
  'Outfit',
  'Figtree',
  'Space Grotesk',
  'Plus Jakarta Sans',
  'Albert Sans',
  // Serif
  'Merriweather',
  'Playfair Display',
  'Lora',
  'Roboto Slab',
  'PT Serif',
  'Source Serif 4',
  'Bitter',
  // Monospace
  'Roboto Mono',
  'JetBrains Mono',
  'Fira Code',
  'Source Code Pro',
  'IBM Plex Mono',
  'Space Mono',
];
