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
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: brutalLine(cs), width: 2)),
      ),
      child: Row(
        children: [
          const Spacer(),
          _action(cs, Icons.notifications_none_rounded, 'Notifications', () {}),
          const SizedBox(width: 8),
          _action(cs, Icons.settings_outlined, 'Settings',
              () => ref.read(navIndexProvider.notifier).select(3)),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary,
              border: Border.all(color: brutalLine(cs), width: 2),
            ),
            child: Icon(Icons.person_rounded, size: 18, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _action(
      ColorScheme cs, IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(color: brutalLine(cs), width: 1.5),
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
