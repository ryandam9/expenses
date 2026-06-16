import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nav_provider.dart';
import '../theme/brutalism.dart';

/// A slim application header with quick-action icons (notifications, settings,
/// profile). Search lives on the Transactions screen itself, so it is not
/// duplicated here.
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedIndex = ref.watch(navIndexProvider);
    const labels = ['Dashboard', 'Transactions', 'Categories', 'Settings'];
    const subtitles = [
      'Portfolio overview',
      'Ledger analysis',
      'Category explorer',
      'Workspace controls',
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(18, 0, 16, 0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: brutalLine(cs), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels[selectedIndex],
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              Text(
                subtitles[selectedIndex],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          const _CommandPalette(),
          const SizedBox(width: 8),
          _action(cs, Icons.notifications_none_rounded, 'Notifications', () {}),
          const SizedBox(width: 8),
          _action(
            cs,
            Icons.settings_outlined,
            'Settings',
            () => ref.read(navIndexProvider.notifier).select(3),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary,
              border: Border.all(color: cs.primary.withValues(alpha: 0.32)),
            ),
            child: Icon(Icons.person_rounded, size: 18, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _action(
    ColorScheme cs,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(color: brutalLine(cs), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _CommandPalette extends ConsumerWidget {
  const _CommandPalette();

  static const _destinations =
      <({String title, String subtitle, IconData icon, int index})>[
        (
          title: 'Dashboard',
          subtitle: 'Open summary and monthly insights',
          icon: Icons.dashboard_rounded,
          index: 0,
        ),
        (
          title: 'Transactions',
          subtitle: 'Search, filter, inspect, and export rows',
          icon: Icons.receipt_long_rounded,
          index: 1,
        ),
        (
          title: 'Categories',
          subtitle: 'Explore spending by selected categories',
          icon: Icons.category_rounded,
          index: 2,
        ),
        (
          title: 'Settings',
          subtitle: 'Change database, theme, typography, and preferences',
          icon: Icons.tune_rounded,
          index: 3,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SearchAnchor(
      isFullScreen: false,
      viewHintText: 'Jump to...',
      viewConstraints: const BoxConstraints(maxWidth: 430, maxHeight: 360),
      builder: (context, controller) {
        return Tooltip(
          message: 'Command palette',
          child: IconButton.filledTonal(
            icon: const Icon(Icons.search_rounded, size: 20),
            onPressed: controller.openView,
          ),
        );
      },
      suggestionsBuilder: (context, controller) {
        final query = controller.text.trim().toLowerCase();
        final visible = query.isEmpty
            ? _destinations
            : _destinations
                  .where(
                    (d) =>
                        d.title.toLowerCase().contains(query) ||
                        d.subtitle.toLowerCase().contains(query),
                  )
                  .toList();
        if (visible.isEmpty) {
          return [
            ListTile(
              leading: Icon(Icons.search_off_rounded, color: cs.outline),
              title: const Text('No matching workspace'),
              subtitle: const Text(
                'Try dashboard, transactions, categories, or settings',
              ),
            ),
          ];
        }
        return [
          for (final d in visible)
            ListTile(
              leading: Icon(d.icon, color: cs.primary),
              title: Text(d.title),
              subtitle: Text(d.subtitle),
              onTap: () {
                ref.read(navIndexProvider.notifier).select(d.index);
                controller.closeView(d.title);
              },
            ),
        ];
      },
    );
  }
}
