import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/prefs_provider.dart';
import '../theme/app_ui.dart';
import '../theme/brutalism.dart';
import '../theme/typography.dart';
import '../widgets/db_path_dialog.dart';

/// Settings & customization, laid out as a responsive grid of cards
/// (Appearance, Database, About) over the app's tinted canvas.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeader(
            icon: Icons.tune_rounded,
            title: 'Settings & Customization',
            subtitle: 'Manage your data source and preferences.',
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
                          children: [database, SizedBox(height: 18), about],
                        );
                      }
                      return const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: database),
                          SizedBox(width: 18),
                          Expanded(child: about),
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
/// "APPEARANCE / DATABASE / ABOUT" panels).
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
      decoration: brutalBox(cs, radius: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: cs.onSurfaceVariant,
                ),
              ),
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
          letterSpacing: 0,
        ),
      ),
    );

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
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SQLite File Path',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: path == null
                          ? Text(
                              '/path/to/your/database.sqlite',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            )
                          : SelectableText(
                              path,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall,
                            ),
                    ),
                    if (connected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Tooltip(
                          message: 'Connected',
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
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
                minimumSize: const Size(0, 32),
              ),
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
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: cs.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Expenses Dashboard',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                'v1.0.0',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Facts as small tiles rather than plain rows.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _factTile(
              theme,
              Icons.receipt_long_rounded,
              'Transactions',
              count == null ? '—' : NumberFormat.decimalPattern().format(count),
            ),
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
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: dashboardNumberStyle(theme.textTheme.labelLarge),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
