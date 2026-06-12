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
import '../widgets/db_path_dialog.dart';

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
                  bottom: BorderSide(color: cs.outlineVariant, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text('Personalize the dashboard',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                  children: const [
                    _Section(
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: 'Brightness, colour intensity and theme',
                      child: _AppearanceControls(),
                    ),
                    SizedBox(height: 18),
                    _Section(
                      icon: Icons.text_fields_rounded,
                      title: 'Typography',
                      subtitle: 'Font family and text size',
                      child: _TypographyControls(),
                    ),
                    SizedBox(height: 18),
                    _Section(
                      icon: Icons.storage_rounded,
                      title: 'Data source',
                      subtitle: 'Where your transactions come from',
                      child: _DataSourceControls(),
                    ),
                    SizedBox(height: 18),
                    _Section(
                      icon: Icons.info_outline_rounded,
                      title: 'About',
                      subtitle: 'App information',
                      child: _AboutBlock(),
                    ),
                  ],
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
/// An elevated settings card with an icon-chip header and subtitle inside it,
/// sharing the dashboard's card chrome.
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerLowest,
            Color.alphaBlend(
                cs.primary.withValues(alpha: 0.04), cs.surfaceContainerLowest),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.18),
                      cs.tertiary.withValues(alpha: 0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  Text(subtitle,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Small-caps label introducing a group of controls inside a section.
Widget _groupLabel(ThemeData theme, String text, {double bottom = 10}) =>
    Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
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
        _groupLabel(theme, 'Mode'),
        const _ModePreviewSelector(),
        const SizedBox(height: 22),
        _groupLabel(theme, 'Colour intensity'),
        const _VariantSelector(),
        const SizedBox(height: 22),
        _groupLabel(theme, 'Theme'),
        const _ThemeGrid(),
      ],
    );
  }
}

// ------------------------------------------------------------ mode previews
/// System / Light / Dark as miniature dashboard mock-ups (the System card is
/// split half-light, half-dark), so the choice is visual rather than verbal.
class _ModePreviewSelector extends ConsumerWidget {
  const _ModePreviewSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Row(
      children: [
        for (final m in ThemeMode.values) ...[
          Expanded(
            child: _ModeCard(
              mode: m,
              selected: mode == m,
              onTap: () => ref.read(themeModeProvider.notifier).select(m),
            ),
          ),
          if (m != ThemeMode.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  static const _labels = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = switch (mode) {
      ThemeMode.light => _MiniDashboard(dark: false, accent: cs.primary),
      ThemeMode.dark => _MiniDashboard(dark: true, accent: cs.primary),
      // System: light underneath, the right half overlaid in dark.
      ThemeMode.system => Stack(
          fit: StackFit.expand,
          children: [
            _MiniDashboard(dark: false, accent: cs.primary),
            ClipRect(
              clipper: _RightHalfClipper(),
              child: _MiniDashboard(dark: true, accent: cs.primary),
            ),
          ],
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 72, width: double.infinity, child: preview),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _labels[mode]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: selected ? 1 : 0,
                    child: Icon(Icons.check_circle_rounded,
                        size: 16, color: cs.primary),
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

/// Clips to the right half of its child (for the System mode's split card).
class _RightHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width / 2, 0, size.width, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// A tiny abstract dashboard — sidebar, header strip, content lines and a
/// little chart — drawn in either light or dark neutrals with the current
/// theme's accent.
class _MiniDashboard extends StatelessWidget {
  final bool dark;
  final Color accent;
  const _MiniDashboard({required this.dark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF20242B) : const Color(0xFFF2F3F6);
    final surface = dark ? const Color(0xFF2C313A) : Colors.white;
    final line = dark ? const Color(0xFF49505C) : const Color(0xFFDCDFE6);

    Widget bar(double w, double h, Color c, [double r = 3]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar.
          Container(
            width: 13,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(3),
            child: Column(
              children: [
                bar(7, 7, accent, 2),
                const SizedBox(height: 3),
                bar(7, 3, line, 1.5),
                const SizedBox(height: 2),
                bar(7, 3, line, 1.5),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Content: header strip, text lines, mini bar chart.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(double.infinity, 6, accent.withValues(alpha: 0.85)),
                const SizedBox(height: 4),
                bar(double.infinity, 4, line),
                const SizedBox(height: 3),
                FractionallySizedBox(
                    widthFactor: 0.65, child: bar(double.infinity, 4, line)),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bar(6, 10, accent.withValues(alpha: 0.55)),
                    const SizedBox(width: 3),
                    bar(6, 16, accent),
                    const SizedBox(width: 3),
                    bar(6, 7, accent.withValues(alpha: 0.4)),
                    const SizedBox(width: 3),
                    bar(6, 12, accent.withValues(alpha: 0.7)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- scheme variant
/// How strongly the seed colours are expressed in the derived scheme
/// (ColorScheme.fromSeed's dynamicSchemeVariant).
class _VariantSelector extends ConsumerWidget {
  const _VariantSelector();

  static const _labels = <DynamicSchemeVariant, (String, String, IconData)>{
    DynamicSchemeVariant.tonalSpot: (
      'Tonal',
      'Calm, balanced colours',
      Icons.blur_circular
    ),
    DynamicSchemeVariant.vibrant: (
      'Vibrant',
      'Richer, more saturated',
      Icons.water_drop_outlined
    ),
    DynamicSchemeVariant.expressive: (
      'Expressive',
      'Bold and colourful',
      Icons.brush_outlined
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final variant = ref.watch(schemeVariantProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<DynamicSchemeVariant>(
            segments: [
              for (final v in schemeVariants)
                ButtonSegment(
                  value: v,
                  label: Text(_labels[v]!.$1),
                  icon: Icon(_labels[v]!.$3, size: 18),
                ),
            ],
            selected: {variant},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(schemeVariantProvider.notifier).select(s.first),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _labels[variant]!.$2,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
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
            mainAxisExtent: 118,
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

class _ThemeCard extends StatefulWidget {
  final AppTheme appTheme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.appTheme,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = widget.appTheme;
    final selected = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        scale: _hovered ? 1.03 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
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
                // The selected theme glows softly in its own primary colour.
                boxShadow: selected || _hovered
                    ? [
                        BoxShadow(
                          color: t.primary
                              .withValues(alpha: selected ? 0.28 : 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
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
                            t.primary,
                            t.secondary,
                            t.tertiary,
                          ]),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            decoration: const BoxDecoration(
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
                  // The chart palette this theme will paint data with.
                  Row(
                    children: [
                      for (final c in t.chartColors) ...[
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(t.icon,
                          size: 15,
                          color: selected ? cs.primary : cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.name,
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
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- typography
class _TypographyControls extends ConsumerWidget {
  const _TypographyControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
          helperText: 'The whole Google Fonts catalogue — type to search',
          // Entries are plain text: with ~1,800 families, rendering each in
          // its own font would download them all; the specimen panel below
          // previews the selected one instead.
          dropdownMenuEntries: [
            for (final f in systemFonts) DropdownMenuEntry(value: f, label: f),
          ],
          onSelected: (v) {
            if (v != null) ref.read(fontFamilyProvider.notifier).select(v);
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _groupLabel(theme, 'Text size', bottom: 0),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${fontSize.toStringAsFixed(0)}px',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer)),
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
        const SizedBox(height: 10),
        // Live specimen in the chosen font (the app-wide text theme already
        // carries it, so plain styles inherit the selection).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.07),
                cs.tertiary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text('\$12,480.50',
                  style: TextStyle(
                      fontSize: fontSize * 2.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1)),
              const SizedBox(height: 6),
              Text('The quick brown fox jumps over the lazy dog.',
                  style: TextStyle(fontSize: fontSize)),
              const SizedBox(height: 4),
              Text('1,234,567.89  ·  spent across 12 categories',
                  style: TextStyle(
                      fontSize: fontSize * 0.85, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
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
    final statusColor =
        connected ? Colors.green.shade700 : Colors.orange.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _groupLabel(theme, 'Database file', bottom: 0),
            const Spacer(),
            // Connection status pill.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      connected
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 13,
                      color: statusColor),
                  const SizedBox(width: 5),
                  Text(connected ? 'Connected' : 'Not configured',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
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
                    ? Text('Choose the SQLite file with your expenses table.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: cs.onSurfaceVariant))
                    : SelectableText(path, style: theme.textTheme.bodySmall),
              ),
              if (connected)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy path',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: path)),
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
            label: Text(connected ? 'Change data source' : 'Choose database…'),
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
