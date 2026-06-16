# CLAUDE.md

Guidance for Claude Code (and other agents) working in this repository.

## What this is

**Expenses Dashboard** — a **Flutter desktop** app (Linux / macOS / Windows) for
exploring expense transactions stored in a local **SQLite** database. State
management is **Riverpod**; the UI uses a custom "refined brutalist" theme.

## ALWAYS install Flutter and run the tests

This environment does **not** ship with Flutter preinstalled, and code changes
must never be committed without being verified. At the start of any task that
touches code, install Flutter (if missing) and run the analyzer and the test
suite — and run them again before every commit / before opening or updating a PR.

```bash
# 1. Install Flutter (stable channel) if it isn't already on PATH.
if ! command -v flutter >/dev/null 2>&1 && [ ! -x /opt/flutter/bin/flutter ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter
fi
export PATH="/opt/flutter/bin:$PATH"
git config --global --add safe.directory /opt/flutter

# 2. Fetch deps, analyze, and test. All three must be clean before committing.
flutter pub get
flutter analyze      # required: "No issues found!"
flutter test         # required: "All tests passed!"
```

Notes:
- The project requires Dart SDK `^3.12.0`; Flutter stable ≥ 3.44 provides it.
- Cloning Flutter + the first run downloads ~450 MB and takes a few minutes.
- A harmless `FilterPanel: failed to load filter options: No data source
  configured` line appears during widget tests — it's an expected `debugPrint`,
  not a failure.

## Project layout

- `lib/main.dart` — entry point; builds the light/dark `ThemeData` and applies the
  baked-in fonts.
- `lib/theme/` — `app_themes.dart` (colour schemes), `brutalism.dart` (card / border
  / shadow primitives), `typography.dart` (fonts + number styles), `app_ui.dart`
  (page header & section title).
- `lib/screens/` — `dashboard_screen.dart` (Summary), `transactions_screen.dart`,
  `categories_screen.dart`, `settings_screen.dart`, `main_shell.dart` (sidebar/nav).
- `lib/widgets/` — shared widgets (filter panel, top bar, charts, category pill, …).
- `lib/providers/` — Riverpod providers (theme, filters, dashboard data, prefs, nav).
- `lib/services/` — `database_service.dart`, `query_builder.dart` (SQLite access).
- `test/` — unit and widget tests.

## Design language ("refined brutalist")

- Build surfaces with `brutalBox` / `brutalLine` / `brutalShadow` from
  `theme/brutalism.dart` (slate borders + one small hard offset shadow) rather than
  ad-hoc borders/shadows.
- Fonts are fixed: **Space Grotesk** for UI, **JetBrains Mono** for figures, via
  `appTextTheme`, `dashboardNumberStyle`, `tableNumberStyle` in
  `theme/typography.dart`. There is no runtime font picker — do not reintroduce one.
- Colour: brand colours are pinned only in **light** mode; **dark** mode derives
  lighter accent tones so accent-coloured text/icons stay legible. Don't pin dark
  primaries.
- Prefer `ColorScheme` roles and theme helpers over hardcoded colours. A hardcoded
  `Colors.white` on a themed fill breaks in one brightness — use `onPrimary` /
  `onSurface`, or choose with `ThemeData.estimateBrightnessForColor`.

## Conventions

- Match the surrounding code style and keep comments at the existing density.
- Develop on the feature branch you were given; commit with clear messages.
- Run `flutter analyze` and `flutter test` before every commit (see above).
