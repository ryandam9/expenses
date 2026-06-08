import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import '../providers/nav_provider.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedIndex = ref.watch(navIndexProvider);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) =>
                ref.read(navIndexProvider.notifier).select(i),
            extended: false,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: selectedIndex == 0 ? 0.05 : 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.monetization_on,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            indicatorColor: theme.colorScheme.primaryContainer,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(16),
                right: Radius.circular(16),
              ),
            ),
            backgroundColor: theme.colorScheme.surface,
            labelType: NavigationRailLabelType.all,
            unselectedLabelTextStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedLabelTextStyle: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: theme.colorScheme.onSurface,
            ),
            unselectedIconTheme: IconThemeData(
              color: theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
            selectedIconTheme: IconThemeData(
              color: theme.colorScheme.primary,
              size: 26,
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: selectedIndex == 0
                  ? const DashboardScreen(key: ValueKey('dashboard'))
                  : const SettingsScreen(key: ValueKey('settings')),
            ),
          ),
        ],
      ),
    );
  }
}
