import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_themes.dart';
import '../services/database_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/font_provider.dart';
import '../providers/prefs_provider.dart';
import '../theme/brutalism.dart';
import '../widgets/db_path_dialog.dart';

/// Settings & customization, laid out as a responsive grid of cards
/// (Appearance, Typography, Database, About) over the app's tinted canvas.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page header, matching the dashboard's.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                  bottom: BorderSide(color: brutalLine(cs), width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings & Customization',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text(
                    'Manage your profile, security preferences, and interface '
                    'appearance.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 48),
                  child: LayoutBuilder(
                    builder: (context, c) {
                      // Two columns on wide windows, single column when narrow.
                      final twoCol = c.maxWidth >= 720;
                      const appearance = _Section(
                        icon: Icons.palette_outlined,
                        title: 'APPEARANCE',
                        child: _AppearanceControls(),
                      );
                      const typography = _Section(
                        icon: Icons.text_fields_rounded,
                        title: 'TYPOGRAPHY',
                        child: _TypographyControls(),
                      );
                      const database = _Section(
                        icon: Icons.storage_rounded,
                        title: 'DATABASE',
                        child: _DataSourceControls(),
                      );
                      const about = _Section(
                        icon: Icons.info_outline_rounded,
                        title: 'ABOUT',
                        child: _AboutBlock(),
                      );

                      if (!twoCol) {
                        return const Column(
                          children: [
                            appearance,
                            SizedBox(height: 18),
                            typography,
                            SizedBox(height: 18),
                            database,
                            SizedBox(height: 18),
                            about,
                          ],
                        );
                      }
                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                appearance,
                                SizedBox(height: 18),
                                database,
                              ],
                            ),
                          ),
                          SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              children: [
                                typography,
                                SizedBox(height: 18),
                                about,
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ section
/// A settings card with a small-caps, icon-led header (matching the mockup's
/// "APPEARANCE / TYPOGRAPHY / DATABASE" panels).
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: brutalBox(cs, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Text(title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: cs.onSurfaceVariant,
                  )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 18),
            child: Divider(height: 1, color: cs.outlineVariant),
          ),
          child,
        ],
      ),
    );
  }
}

/// A bold, dark field label sitting above a control.
Widget _fieldLabel(ThemeData theme, String text, {double bottom = 10}) =>
    Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );

// -------------------------------------------------------------- appearance
class _AppearanceControls extends ConsumerWidget {
  const _AppearanceControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(theme, 'Interface Theme'),
        const _ThemeModeButtons(),
        const SizedBox(height: 24),
        _fieldLabel(theme, 'Accent Color'),
        const _AccentSwatches(),
        const SizedBox(height: 24),
        _fieldLabel(theme, 'Color Intensity'),
        const _VariantSelector(),
      ],
    );
  }
}

// ----------------------------------------------------------- theme mode
/// Light / Dark / System as three side-by-side buttons, the active one tinted
/// and outlined in the primary colour.
class _ThemeModeButtons extends ConsumerWidget {
  const _ThemeModeButtons();

  static const _modes = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, 'Light', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
    (ThemeMode.system, 'System', Icons.desktop_windows_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Row(
      children: [
        for (final m in _modes) ...[
          Expanded(
            child: _ModeButton(
              label: m.$2,
              icon: m.$3,
              selected: mode == m.$1,
              onTap: () => ref.read(themeModeProvider.notifier).select(m.$1),
            ),
          ),
          if (m != _modes.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.10)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- accent swatches
/// The accent palette as a row of circular colour swatches; the active theme
/// is ringed and ticked, mirroring the mockup.
class _AccentSwatches extends ConsumerWidget {
  const _AccentSwatches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(themeIndexProvider);
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (var i = 0; i < appThemes.length; i++)
          _Swatch(
            appTheme: appThemes[i],
            selected: i == selectedIndex,
            onTap: () => ref.read(themeIndexProvider.notifier).select(i),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final AppTheme appTheme;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.appTheme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: appTheme.name,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? appTheme.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [appTheme.primary, appTheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: appTheme.primary.withValues(alpha: 0.35),
                  blurRadius: selected ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- scheme variant
/// How strongly the seed colours are expressed in the derived scheme
/// (ColorScheme.fromSeed's dynamicSchemeVariant).
class _VariantSelector extends ConsumerWidget {
  const _VariantSelector();

  static const _labels = <DynamicSchemeVariant, (String, IconData)>{
    DynamicSchemeVariant.tonalSpot: ('Tonal', Icons.blur_circular),
    DynamicSchemeVariant.vibrant: ('Vibrant', Icons.water_drop_outlined),
    DynamicSchemeVariant.expressive: ('Expressive', Icons.brush_outlined),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(schemeVariantProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<DynamicSchemeVariant>(
        segments: [
          for (final v in schemeVariants)
            ButtonSegment(
              value: v,
              label: Text(_labels[v]!.$1),
              icon: Icon(_labels[v]!.$2, size: 18),
            ),
        ],
        selected: {variant},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        onSelectionChanged: (s) =>
            ref.read(schemeVariantProvider.notifier).select(s.first),
      ),
    );
  }
}

// --------------------------------------------------------------- typography
class _TypographyControls extends ConsumerWidget {
  const _TypographyControls();

  // The base sizes offered by the Density dropdown, kept in sync with the
  // app-wide text scale (main.dart divides by 14).
  static const _densities = <(double, String)>[
    (12, 'Compact (12px)'),
    (14, 'Standard (14px)'),
    (16, 'Comfortable (16px)'),
    (18, 'Large (18px)'),
  ];

  /// The preset whose size is closest to [size], so a stored custom size still
  /// shows a sensible selection.
  double _nearestDensity(double size) {
    var best = _densities.first.$1;
    var bestDiff = (size - best).abs();
    for (final d in _densities) {
      final diff = (size - d.$1).abs();
      if (diff < bestDiff) {
        best = d.$1;
        bestDiff = diff;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final font = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, c) {
          final fontField = _LabeledField(
            label: 'Font Family',
            child: DropdownMenu<String>(
              initialSelection: font,
              expandedInsets: EdgeInsets.zero,
              enableFilter: true,
              requestFocusOnTap: true,
              leadingIcon: const Icon(Icons.font_download_outlined, size: 18),
              menuHeight: 360,
              // Entries are plain text: with ~1,800 families, rendering each in
              // its own font would download them all; the preview below shows
              // the selected one instead.
              dropdownMenuEntries: [
                for (final f in systemFonts)
                  DropdownMenuEntry(value: f, label: f),
              ],
              onSelected: (v) {
                if (v != null) {
                  ref.read(fontFamilyProvider.notifier).select(v);
                }
              },
            ),
          );
          final densityField = _LabeledField(
            label: 'Density / Base Size',
            child: DropdownMenu<double>(
              initialSelection: _nearestDensity(fontSize),
              expandedInsets: EdgeInsets.zero,
              requestFocusOnTap: false,
              dropdownMenuEntries: [
                for (final d in _densities)
                  DropdownMenuEntry(value: d.$1, label: d.$2),
              ],
              onSelected: (v) {
                if (v != null) ref.read(fontSizeProvider.notifier).setSize(v);
              },
            ),
          );
          // Two fields side by side when there's room, stacked when narrow.
          if (c.maxWidth < 420) {
            return Column(
              children: [
                fontField,
                const SizedBox(height: 16),
                densityField,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fontField),
              const SizedBox(width: 16),
              Expanded(child: densityField),
            ],
          );
        }),
        const SizedBox(height: 20),
        // Live specimen in the chosen font (the app-wide text theme already
        // carries it, so plain styles inherit the selection).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: fontSize, height: 1.5),
              children: [
                const TextSpan(
                    text:
                        'The quick brown fox jumps over the lazy dog. This is '
                        'a preview of your selected typography settings in the '),
                TextSpan(
                  text: 'Expenses',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' environment.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A small label above a form control, used inside the Typography card.
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// -------------------------------------------------------------- data source
class _DataSourceControls extends ConsumerWidget {
  const _DataSourceControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Rebuild when the path changes.
    ref.watch(dbPathProvider);
    final path = DatabaseService().currentPath;
    final connected = path != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(theme, 'Database Source', bottom: 6),
        Text(
          'Connect a local SQLite database to power your dashboard with '
          'real-time data.',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text('SQLite File Path',
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: path == null
                          ? Text('/path/to/your/database.sqlite',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.7)))
                          : SelectableText(path,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall),
                    ),
                    if (connected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Tooltip(
                          message: 'Connected',
                          child: Icon(Icons.check_circle_rounded,
                              size: 16, color: Colors.green.shade600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => showDbPathDialog(context, ref),
              child: const Text('Browse'),
            ),
          ],
        ),
        if (connected) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: path)),
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Copy path'),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32)),
            ),
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------------- about
class _AboutBlock extends ConsumerWidget {
  const _AboutBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Live count from the configured database ('—' until one is configured).
    final countAsync = ref.watch(transactionCountProvider);
    final count = countAsync.hasValue ? countAsync.requireValue : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.tertiary],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  color: cs.onPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Expenses Dashboard',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text('v1.0.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Facts as small tiles rather than plain rows.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _factTile(theme, Icons.receipt_long_rounded, 'Transactions',
                count == null
                    ? '—'
                    : NumberFormat.decimalPattern().format(count)),
            _factTile(theme, Icons.storage_rounded, 'Data source', 'SQLite'),
            _factTile(theme, Icons.flutter_dash, 'Built with', 'Flutter'),
          ],
        ),
      ],
    );
  }

  Widget _factTile(ThemeData theme, IconData icon, String label, String value) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      letterSpacing: 0.7,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
              Text(value,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
