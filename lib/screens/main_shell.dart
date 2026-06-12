import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import '../providers/nav_provider.dart';
import '../providers/theme_provider.dart';

/// App frame: a branded sidebar (logo, navigation, theme toggle) next to the
/// active screen. Both screens stay mounted in an [IndexedStack] so switching
/// away and back never loses in-progress state (filters, search, table page,
/// scroll positions).
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Sidebar(),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              sizing: StackFit.expand,
              children: const [
                DashboardScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedIndex = ref.watch(navIndexProvider);

    return Container(
      width: 212,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(right: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------------------------------------------------------ brand
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.account_balance_wallet_rounded,
                      size: 20, color: cs.onPrimary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Expenses',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ------------------------------------------------------- navigation
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: selectedIndex == 0,
            onTap: () => ref.read(navIndexProvider.notifier).select(0),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
            selected: selectedIndex == 1,
            onTap: () => ref.read(navIndexProvider.notifier).select(1),
          ),
          const Spacer(),
          // ---------------------------------------------------------- footer
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _ThemeModeToggle(),
          ),
        ],
      ),
    );
  }
}

/// One sidebar destination: a pill that tints and gains a primary accent bar
/// when selected, with the standard hover/press overlays on desktop.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.11)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick light/dark switch. Resolves the effective brightness (including
/// "system") and flips to the explicit opposite; full mode control, including
/// returning to "system", stays in Settings.
class _ThemeModeToggle extends ConsumerWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mode = ref.watch(themeModeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = switch (mode) {
      ThemeMode.system => platformDark,
      ThemeMode.dark => true,
      ThemeMode.light => false,
    };

    return Material(
      color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref
            .read(themeModeProvider.notifier)
            .select(isDark ? ThemeMode.light : ThemeMode.dark),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(isDark),
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isDark ? 'Dark mode' : 'Light mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(Icons.swap_horiz_rounded,
                  size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
