import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_themes.dart';
import '../services/database_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/font_provider.dart';
import '../providers/prefs_provider.dart';
import '../widgets/db_path_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              _Section(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                theme: theme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModeSelector(theme: theme),
                    const SizedBox(height: 20),
                    Text('Color intensity',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const _VariantSelector(),
                    const SizedBox(height: 20),
                    Text('Color theme',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const _ThemeGrid(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(
                icon: Icons.storage_rounded,
                title: 'Data source',
                theme: theme,
                child: const _DataSourceControls(),
              ),
              const SizedBox(height: 20),
              _Section(
                icon: Icons.text_fields_rounded,
                title: 'Typography',
                theme: theme,
                child: const _TypographyControls(),
              ),
              const SizedBox(height: 20),
              _Section(
                icon: Icons.info_outline_rounded,
                title: 'About',
                theme: theme,
                child: const _AboutBlock(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- mode selector
class _ModeSelector extends ConsumerWidget {
  final ThemeData theme;
  const _ModeSelector({required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_rounded, size: 18)),
          ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_rounded, size: 18)),
          ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_rounded, size: 18)),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) =>
            ref.read(themeModeProvider.notifier).select(s.first),
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
        onSelectionChanged: (s) =>
            ref.read(schemeVariantProvider.notifier).select(s.first),
      ),
    );
  }
}

// ------------------------------------------------------------------- theme grid
class _ThemeGrid extends ConsumerWidget {
  const _ThemeGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(themeIndexProvider);
    return LayoutBuilder(
      builder: (context, c) {
        // Pack as many ~190px cards across as the width allows.
        final cols = (c.maxWidth / 190).floor().clamp(1, 5);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appThemes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, i) => _ThemeCard(
            appTheme: appThemes[i],
            selected: i == selectedIndex,
            onTap: () => ref.read(themeIndexProvider.notifier).select(i),
          ),
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppTheme appTheme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.appTheme,
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
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.06)
                : cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Palette swatch: the theme's three seed colours as a band.
              Stack(
                children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: LinearGradient(colors: [
                        appTheme.primary,
                        appTheme.secondary,
                        appTheme.tertiary,
                      ]),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle,
                            size: 18, color: cs.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(appTheme.icon,
                      size: 15,
                      color: selected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appTheme.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Database file',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: path == null
                    ? Text('Not configured',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant))
                    : SelectableText(
                        path,
                        style: theme.textTheme.bodySmall,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => showDbPathDialog(context, ref),
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: const Text('Change data source'),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- typography
class _TypographyControls extends ConsumerWidget {
  const _TypographyControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final font = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          initialSelection: font,
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          label: const Text('Font family'),
          leadingIcon: const Icon(Icons.font_download_outlined, size: 18),
          menuHeight: 360,
          dropdownMenuEntries: systemFonts.map((f) {
            // Render each option in its own font so the list previews itself.
            TextStyle? style;
            if (f != 'System Default') {
              try {
                style = GoogleFonts.getFont(f);
              } catch (_) {
                style = null;
              }
            }
            return DropdownMenuEntry(
              value: f,
              label: f,
              labelWidget: Text(f, style: style),
            );
          }).toList(),
          onSelected: (v) {
            if (v != null) ref.read(fontFamilyProvider.notifier).select(v);
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Text size',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${fontSize.toStringAsFixed(0)}px',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer)),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.text_decrease_rounded, size: 18),
            Expanded(
              child: Slider(
                value: fontSize,
                min: 10,
                max: 20,
                divisions: 10,
                label: '${fontSize.toStringAsFixed(0)}px',
                onChanged: (v) =>
                    ref.read(fontSizeProvider.notifier).setSize(v),
              ),
            ),
            const Icon(Icons.text_increase_rounded, size: 22),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerLow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text('The quick brown fox jumps over the lazy dog.',
                  style: TextStyle(fontSize: fontSize)),
              const SizedBox(height: 4),
              Text('1,234,567.89  ·  \$2,480 spent this month',
                  style: TextStyle(
                      fontSize: fontSize * 0.85,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
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
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.monetization_on,
                  color: cs.onPrimaryContainer, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expenses Dashboard',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('Version 1.0.0',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _AboutRow(
            icon: Icons.storage_rounded, label: 'Data source', value: 'SQLite'),
        _AboutRow(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            value: count == null
                ? '—'
                : NumberFormat.decimalPattern().format(count)),
        const _AboutRow(
            icon: Icons.flutter_dash, label: 'Built with', value: 'Flutter'),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AboutRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ section
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeData theme;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: child,
        ),
      ],
    );
  }
}
