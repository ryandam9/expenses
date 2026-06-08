import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_themes.dart';
import '../providers/theme_provider.dart';
import '../providers/font_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeIndex = ref.watch(themeIndexProvider);
    final font = ref.watch(fontFamilyProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(icon: Icons.palette, title: 'Theme', theme: theme),
          const SizedBox(height: 8),
          Card.filled(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(appThemes.length, (i) {
                final t = appThemes[i];
                final selected = i == themeIndex;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    selected ? Icons.check_circle : t.icon,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  title: Text(
                    t.name,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: selected
                      ? Text('Active', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600))
                      : null,
                  selected: selected,
                  onTap: () => ref.read(themeIndexProvider.notifier).select(i),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(icon: Icons.text_fields, title: 'Typography', theme: theme),
          const SizedBox(height: 8),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownMenu<String>(
                    initialSelection: font,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Font Family'),
                    inputDecorationTheme: InputDecorationTheme(
                      border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      isDense: true,
                    ),
                    menuStyle: MenuStyle(
                      shape: WidgetStateProperty.all(
                        const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                    ),
                    dropdownMenuEntries: systemFonts.map((f) {
                      final preview = f == 'Google Sans'
                          ? GoogleFonts.googleSansTextTheme()
                          : f == 'Inter'
                              ? GoogleFonts.interTextTheme()
                              : f == 'Space Grotesk'
                                  ? GoogleFonts.spaceGroteskTextTheme()
                                  : f == 'JetBrains Mono'
                                      ? GoogleFonts.jetBrainsMonoTextTheme()
                                      : null;
                      return DropdownMenuEntry(
                        value: f,
                        label: f,
                        labelWidget: Text(f, style: preview?.bodyMedium),
                      );
                    }).toList(),
                    onSelected: (v) {
                      if (v != null) {
                        ref.read(fontFamilyProvider.notifier).select(v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.format_size, size: 16),
                      Expanded(
                        child: Slider.adaptive(
                          value: fontSize,
                          min: 10,
                          max: 20,
                          divisions: 10,
                          label: '${fontSize.toStringAsFixed(0)}px',
                          onChanged: (v) =>
                              ref.read(fontSizeProvider.notifier).setSize(v),
                        ),
                      ),
                      Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${fontSize.toStringAsFixed(0)}px',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surfaceContainerLow,
                    ),
                    child: Text(
                      'The quick brown fox jumps over the lazy dog.',
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(icon: Icons.info_outline, title: 'About', theme: theme),
          const SizedBox(height: 8),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Expenses Dashboard', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: const Text('Details', style: TextStyle(fontSize: 13)),
                    leading: Icon(Icons.more_horiz, size: 18, color: theme.colorScheme.primary),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.info_outline, size: 18),
                        title: const Text('Version', style: TextStyle(fontSize: 12)),
                        trailing: const Text('1.0.0', style: TextStyle(fontSize: 12)),
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.storage, size: 18),
                        title: const Text('Data Source', style: TextStyle(fontSize: 12)),
                        trailing: const Text('SQLite', style: TextStyle(fontSize: 12)),
                      ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.receipt_long, size: 18),
                        title: const Text('Transactions', style: TextStyle(fontSize: 12)),
                        trailing: const Text('~6,300', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog.adaptive(
                          icon: const Icon(Icons.favorite),
                          title: const Text('Expenses Dashboard'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Built with Flutter 3.44'),
                              SizedBox(height: 12),
                              Text('Features:'),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check, size: 14),
                                  SizedBox(width: 8),
                                  Text('Multi-category filtering', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.check, size: 14),
                                  SizedBox(width: 8),
                                  Text('Custom date ranges', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.check, size: 14),
                                  SizedBox(width: 8),
                                  Text('Theme & font customization', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.check, size: 14),
                                  SizedBox(width: 8),
                                  Text('Charts & tables', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            FilledButton.tonal(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text('About this app', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeData theme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(title, style: theme.textTheme.titleMedium),
      ],
    );
  }
}
