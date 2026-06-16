import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nav_provider.dart';

/// The persistent application header: a global transaction search on the left
/// and quick-action icons (notifications, settings, profile) on the right.
/// The search field is bound to [globalSearchProvider]; typing here jumps to
/// the Transactions screen and filters its table.
class TopBar extends ConsumerStatefulWidget {
  const TopBar({super.key});

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Reflect external changes (e.g. the Transactions clear button) back into
    // the field without disturbing the caret while typing here.
    ref.listen<String>(globalSearchProvider, (prev, next) {
      if (_ctrl.text != next) {
        _ctrl.text = next;
        _ctrl.selection = TextSelection.collapsed(offset: next.length);
      }
    });

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Search transactions…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      ref.read(globalSearchProvider.notifier).set(v);
                      // Surface results where they live.
                      if (v.isNotEmpty && ref.read(navIndexProvider) != 1) {
                        ref.read(navIndexProvider.notifier).select(1);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: Icon(Icons.notifications_none_rounded,
                color: cs.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => ref.read(navIndexProvider.notifier).select(3),
            icon: Icon(Icons.settings_outlined, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.tertiary],
              ),
            ),
            child: Icon(Icons.person_rounded, size: 18, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}
