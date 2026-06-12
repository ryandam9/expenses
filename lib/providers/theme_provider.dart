import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_themes.dart';
import 'prefs_provider.dart';

class ThemeIndexNotifier extends Notifier<int> {
  @override
  int build() {
    final i = ref.read(sharedPreferencesProvider).getInt('themeIndex') ?? 0;
    return i.clamp(0, appThemes.length - 1);
  }

  void select(int index) {
    state = index;
    ref.read(sharedPreferencesProvider).setInt('themeIndex', index);
  }
}

final themeIndexProvider =
    NotifierProvider<ThemeIndexNotifier, int>(ThemeIndexNotifier.new);

/// Light / dark / follow-system. Defaults to following the system, mirroring
/// the companion attendance-register app.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final i = ref.read(sharedPreferencesProvider).getInt('themeMode') ??
        ThemeMode.system.index;
    return ThemeMode.values[i.clamp(0, ThemeMode.values.length - 1)];
  }

  void select(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setInt('themeMode', mode.index);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// How strongly the seed colours are expressed in the derived colour scheme,
/// via [ColorScheme.fromSeed]'s `dynamicSchemeVariant`. A curated subset:
/// tonalSpot is Material's calm default; vibrant and expressive push more
/// chroma into containers and surfaces.
const schemeVariants = <DynamicSchemeVariant>[
  DynamicSchemeVariant.tonalSpot,
  DynamicSchemeVariant.vibrant,
  DynamicSchemeVariant.expressive,
];

class SchemeVariantNotifier extends Notifier<DynamicSchemeVariant> {
  @override
  DynamicSchemeVariant build() {
    // Default to vibrant: the calm tonalSpot default read as washed-out.
    final i = ref.read(sharedPreferencesProvider).getInt('schemeVariant') ?? 1;
    return schemeVariants[i.clamp(0, schemeVariants.length - 1)];
  }

  void select(DynamicSchemeVariant variant) {
    state = variant;
    final i = schemeVariants.indexOf(variant);
    ref
        .read(sharedPreferencesProvider)
        .setInt('schemeVariant', i < 0 ? 0 : i);
  }
}

final schemeVariantProvider =
    NotifierProvider<SchemeVariantNotifier, DynamicSchemeVariant>(
        SchemeVariantNotifier.new);
