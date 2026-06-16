import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/dashboard_provider.dart';
import '../providers/nav_provider.dart';
import '../services/database_service.dart';
import '../services/query_builder.dart';
import '../theme/brutalism.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/category_pill.dart';

/// The Summary dashboard: a high-level snapshot computed entirely from the
/// configured SQLite database (all-time, transfers excluded) — totals, the
/// category breakdown and the most recent transactions. Rendered in the app's
/// neo-brutalist style: flat fills, thick borders, hard offset shadows.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final async = ref.watch(allExpensesProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                  bottom: BorderSide(color: brutalLine(cs), width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text('Your spending at a glance, straight from your database.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(child: _body(context, ref, theme, async)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, ThemeData theme,
      AsyncValue<List<Expense>> async) {
    if (async.isLoading && !async.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (async.hasError && !async.hasValue) {
      final err = async.error;
      final noDb = err is DatabaseNotConfiguredException;
      return _message(
        context,
        ref,
        theme,
        icon: noDb ? Icons.storage_rounded : Icons.error_outline_rounded,
        title: noDb ? 'No database connected' : "Couldn't load your data",
        body: noDb
            ? 'Connect a SQLite database to populate your dashboard.'
            : err.toString(),
        actionLabel: noDb ? 'Open Settings' : null,
      );
    }
    final all = async.requireValue;
    if (all.isEmpty) {
      return _message(context, ref, theme,
          icon: Icons.inbox_rounded,
          title: 'No transactions yet',
          body: 'Your database has no spending to summarise.');
    }

    double expenses = 0, income = 0;
    for (final e in all) {
      expenses += e.debit;
      income += e.credit;
    }
    final net = income - expenses;
    final byCategory = debitTotalsBy(all, (e) => e.category);
    final catEntries = byCategory.entries.toList();
    final maxCat = catEntries.isEmpty ? 0.0 : catEntries.first.value;
    final recent = all.take(6).toList(); // already newest-first

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _kpiRow(theme, expenses, income, net, all.length),
        const SizedBox(height: 22),
        _sectionTitle(theme, 'Expenses by Category'),
        const SizedBox(height: 12),
        _categoryCard(context, ref, theme, catEntries, maxCat, expenses),
        const SizedBox(height: 22),
        _sectionTitle(theme, 'Recent Transactions'),
        const SizedBox(height: 12),
        _recentCard(context, ref, theme, recent),
      ],
    );
  }

  // ------------------------------------------------------------------- KPIs
  Widget _kpiRow(ThemeData theme, double expenses, double income, double net,
      int count) {
    final cs = theme.colorScheme;
    final green = Colors.green.shade600;
    return LayoutBuilder(builder: (context, c) {
      const gap = 14.0;
      final cols = (c.maxWidth / 220).floor().clamp(1, 4);
      final w = (c.maxWidth - (cols - 1) * gap) / cols;
      final tiles = [
        _kpi(theme, w, 'EXPENSES', currency0.format(expenses),
            Icons.south_west_rounded, cs.error),
        _kpi(theme, w, 'INCOME', currency0.format(income),
            Icons.north_east_rounded, green),
        _kpi(theme, w, 'NET', currency0.format(net),
            Icons.swap_vert_rounded, net >= 0 ? green : cs.error),
        _kpi(theme, w, 'TRANSACTIONS',
            NumberFormat.decimalPattern().format(count),
            Icons.receipt_long_rounded, cs.primary),
      ];
      return Wrap(spacing: gap, runSpacing: gap, children: tiles);
    });
  }

  Widget _kpi(ThemeData theme, double w, String label, String value,
      IconData icon, Color accent) {
    final cs = theme.colorScheme;
    return Container(
      width: w,
      padding: const EdgeInsets.all(16),
      decoration: brutalBox(cs, shadowColor: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brutalLine(cs), width: 1.5),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- categories
  Widget _categoryCard(BuildContext context, WidgetRef ref, ThemeData theme,
      List<MapEntry<String, double>> entries, double maxCat, double total) {
    final cs = theme.colorScheme;
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: brutalBox(cs),
        child: Text('No expense data.',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    final shown = entries.take(8).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: brutalBox(cs),
      child: Column(
        children: [
          for (final e in shown)
            _categoryRow(context, ref, theme, e, maxCat, total),
        ],
      ),
    );
  }

  Widget _categoryRow(BuildContext context, WidgetRef ref, ThemeData theme,
      MapEntry<String, double> e, double maxCat, double total) {
    final cs = theme.colorScheme;
    final accent = categoryAccent(context, ref, e.key);
    final pct = maxCat <= 0 ? 0.0 : (e.value / maxCat);
    final share = total <= 0 ? 0.0 : (e.value / total * 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: brutalLine(cs), width: 1.5),
            ),
            child: Center(
                child: FaIcon(categoryIcon(e.key),
                    size: 13, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(prettyCategory(e.key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    Text(currency0.format(e.value),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 42,
                      child: Text('${share.toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _bar(cs, pct, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A chunky, bordered progress bar (neo-brutalist).
  Widget _bar(ColorScheme cs, double pct, Color accent) {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: brutalLine(cs), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.5),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(color: accent),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ recent transactions
  Widget _recentCard(BuildContext context, WidgetRef ref, ThemeData theme,
      List<Expense> recent) {
    final cs = theme.colorScheme;
    return Container(
      decoration: brutalBox(cs),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++)
            _txRow(theme, recent[i], last: i == recent.length - 1),
          InkWell(
            onTap: () => ref.read(navIndexProvider.notifier).select(1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: brutalLine(cs), width: 1.5)),
              ),
              child: Text('View all transactions →',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800, color: cs.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txRow(ThemeData theme, Expense tx, {required bool last}) {
    final cs = theme.colorScheme;
    final isDebit = tx.debit > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(_fmtDate(tx.date),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(tx.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 148, child: CategoryPill(category: tx.category)),
          const SizedBox(width: 12),
          SizedBox(
            width: 116,
            child: Text(currency2.format(tx.amount),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isDebit ? cs.error : Colors.green.shade700)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- shared
  Widget _sectionTitle(ThemeData theme, String title) => Text(
        title,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
      );

  Widget _message(BuildContext context, WidgetRef ref, ThemeData theme,
      {required IconData icon,
      required String title,
      required String body,
      String? actionLabel}) {
    final cs = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(28),
          decoration: brutalBox(cs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brutalLine(cs), width: 2),
                ),
                child: Icon(icon, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              if (actionLabel != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      ref.read(navIndexProvider.notifier).select(3),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('d MMM yyyy').format(d);
  }
}
