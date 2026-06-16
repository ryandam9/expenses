import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'categories_screen.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';
import '../providers/nav_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../theme/app_ui.dart';
import '../theme/brutalism.dart';
import '../widgets/top_bar.dart';

/// App frame: a branded sidebar (logo, navigation, theme toggle) next to the
/// active screen. Both screens stay mounted in an [IndexedStack] so switching
/// away and back never loses in-progress state (filters, search, table page,
/// scroll positions).
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navIndexProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Sidebar(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: appCanvasGradient(cs)),
              child: Column(
                children: [
                  const TopBar(),
                  Expanded(
                    child: IndexedStack(
                      index: selectedIndex,
                      sizing: StackFit.expand,
                      children: const [
                        DashboardScreen(),
                        TransactionsScreen(),
                        CategoriesScreen(),
                        SettingsScreen(),
                      ],
                    ),
                  ),
                ],
              ),
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
    final selectedIndex = ref.watch(navIndexProvider);
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final width = collapsed ? 72.0 : 212.0;

    // The navigation rail is always dark (a deep slate), independent of the
    // app's light/dark mode, for an "institutional" look. Resolving the rail's
    // own dark [ThemeData] from the active accent — and wrapping the rail in it
    // — keeps every descendant (labels, nav pills, toggles) legible on dark
    // without hardcoding a single foreground colour.
    final railTheme = appThemes[ref.watch(themeIndexProvider)].themeData(
      Brightness.dark,
      variant: ref.watch(schemeVariantProvider),
    );
    final theme = railTheme;
    final cs = railTheme.colorScheme;

    return Theme(
      data: railTheme,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: width,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border(right: BorderSide(color: brutalLine(cs), width: 1)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        // While the width animates between the two sizes, lay the content out at
        // its *target* width and clip to the animating width. Otherwise the rows
        // would be measured against an intermediate width too narrow for their
        // fixed parts (logo + gap, icon + label) and overflow on every frame.
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ------------------------------------------------------- brand
                Padding(
                  padding: collapsed
                      ? const EdgeInsets.fromLTRB(0, 20, 0, 22)
                      : const EdgeInsets.fromLTRB(16, 20, 16, 22),
                  child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
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
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 20,
                          color: cs.onPrimary,
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Expenses',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.05,
                                  color: cs.primary,
                                ),
                              ),
                              Text(
                                'Financial Control',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // -------------------------------------------------- navigation
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: selectedIndex == 0,
                  collapsed: collapsed,
                  onTap: () => ref.read(navIndexProvider.notifier).select(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long_rounded,
                  label: 'Transactions',
                  selected: selectedIndex == 1,
                  collapsed: collapsed,
                  onTap: () => ref.read(navIndexProvider.notifier).select(1),
                ),
                _NavItem(
                  icon: Icons.category_outlined,
                  selectedIcon: Icons.category_rounded,
                  label: 'Categories',
                  selected: selectedIndex == 2,
                  collapsed: collapsed,
                  onTap: () => ref.read(navIndexProvider.notifier).select(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: selectedIndex == 3,
                  collapsed: collapsed,
                  onTap: () => ref.read(navIndexProvider.notifier).select(3),
                ),
                const Spacer(),
                // ------------------------------------------------------ footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _CollapseToggle(collapsed: collapsed),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _ThemeModeToggle(collapsed: collapsed),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Collapses or expands the sidebar between full labels and icons only.
class _CollapseToggle extends ConsumerWidget {
  final bool collapsed;
  const _CollapseToggle({required this.collapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final icon = Icon(
      collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
      size: 20,
      color: cs.onSurfaceVariant,
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: collapsed
              ? Center(child: icon)
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Collapse',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return collapsed
        ? Tooltip(message: 'Expand sidebar', child: button)
        : button;
  }
}

/// One sidebar destination: a pill that tints and gains a primary accent bar
/// when selected, with the standard hover/press overlays on desktop.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final navIcon = Icon(selected ? selectedIcon : icon, size: 20, color: fg);
    final item = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: collapsed
                ? const EdgeInsets.symmetric(vertical: 11)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? cs.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: collapsed
                ? Center(child: navIcon)
                : Row(
                    children: [
                      navIcon,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return collapsed ? Tooltip(message: label, child: item) : item;
  }
}

/// Quick light/dark switch. Resolves the effective brightness (including
/// "system") and flips to the explicit opposite; full mode control, including
/// returning to "system", stays in Settings.
class _ThemeModeToggle extends ConsumerWidget {
  final bool collapsed;
  const _ThemeModeToggle({required this.collapsed});

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

    final modeIcon = AnimatedSwitcher(
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
    );

    final toggle = Material(
      color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref
            .read(themeModeProvider.notifier)
            .select(isDark ? ThemeMode.light : ThemeMode.dark),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: collapsed
              ? Center(child: modeIcon)
              : Row(
                  children: [
                    modeIcon,
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
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
        ),
      ),
    );

    return collapsed
        ? Tooltip(
            message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            child: toggle,
          )
        : toggle;
  }
}
