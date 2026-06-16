import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/dashboard_provider.dart';
import '../providers/nav_provider.dart';
import '../utils/format.dart';
import '../widgets/category_pill.dart';

/// The Summary dashboard: a high-level snapshot of monthly spending, budgets
/// and savings goals. Budget and goal figures are illustrative presets (the
/// transaction database does not store targets); the Recent Transactions panel
/// at the bottom is driven by the live data source when one is configured.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _money0 = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

  // ----------------------------------------------------------- demo presets
  static const _budgetSpent = 4250.0;
  static const _budgetTotal = 5000.0;
  static const _incoming = 12450.0;

  static const _categories = <_CatBudget>[
    _CatBudget('Housing', Icons.home_rounded, 2000, 2000),
    _CatBudget('Groceries', Icons.shopping_cart_rounded, 450, 600),
    _CatBudget('Transport', Icons.directions_car_rounded, 330, 300),
    _CatBudget('Entertainment', Icons.movie_rounded, 120, 300),
  ];

  static const _goals = <_Goal>[
    _Goal('Emergency Fund', Icons.shield_rounded, 8000, 10000),
    _Goal('Japan Trip', Icons.flight_rounded, 1750, 5000),
    _Goal('New Car Downpayment', Icons.directions_car_rounded, 2400, 20000),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                Text('Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text('Track your spending and manage your savings targets.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _topCards(theme),
                const SizedBox(height: 26),
                _sectionTitle(theme, 'Expenses per Category'),
                const SizedBox(height: 12),
                _categoryGrid(theme),
                const SizedBox(height: 26),
                _sectionTitle(theme, 'Savings Goals'),
                const SizedBox(height: 12),
                _goalRow(theme),
                const SizedBox(height: 26),
                const _RecentTransactions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- top cards
  Widget _topCards(ThemeData theme) {
    return LayoutBuilder(builder: (context, c) {
      final twoCol = c.maxWidth >= 640;
      final expenses = _expensesCard(theme);
      final incoming = _incomingCard(theme);
      if (!twoCol) {
        return Column(children: [
          expenses,
          const SizedBox(height: 14),
          incoming,
        ]);
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: expenses),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: incoming),
          ],
        ),
      );
    });
  }

  Widget _expensesCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final pct = (_budgetSpent / _budgetTotal).clamp(0.0, 1.0);
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('TOTAL MONTHLY EXPENSES',
                    style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${(pct * 100).round()}% Used',
                    style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(_money.format(_budgetSpent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -1)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text('/ ${_money0.format(_budgetTotal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHigh,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _incomingCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final green = Colors.green.shade600;
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.south_west_rounded, size: 15, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text('TOTAL INCOMING',
                    style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_money.format(_incoming),
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, letterSpacing: -1)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: green),
              const SizedBox(width: 4),
              Flexible(
                child: Text('+2.4% from last month',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: green)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------- category budgets
  Widget _categoryGrid(ThemeData theme) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 14.0;
      final cols = (c.maxWidth / 260).floor().clamp(1, 3);
      final w = (c.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final cat in _categories)
            SizedBox(width: w, child: _categoryCard(theme, cat)),
        ],
      );
    });
  }

  Widget _categoryCard(ThemeData theme, _CatBudget cat) {
    final cs = theme.colorScheme;
    final pct = cat.budget <= 0 ? 0.0 : cat.spent / cat.budget;
    final over = pct > 1.0;
    final barColor = over ? cs.error : cs.primary;
    return _card(
      theme,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cat.icon, size: 18, color: cs.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${(pct * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: over ? cs.error : cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(_money.format(cat.spent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: over ? cs.error : cs.onSurface)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text('/ ${_money.format(cat.budget)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHigh,
              color: barColor,
            ),
          ),
          if (over) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                  'Over budget by ${_money0.format(cat.spent - cat.budget)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: cs.error)),
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------- savings goals
  Widget _goalRow(ThemeData theme) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 14.0;
      final cols = (c.maxWidth / 220).floor().clamp(1, 3);
      final w = (c.maxWidth - (cols - 1) * gap) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final g in _goals)
            SizedBox(width: w, child: _goalCard(theme, g)),
        ],
      );
    });
  }

  Widget _goalCard(ThemeData theme, _Goal goal) {
    final cs = theme.colorScheme;
    final pct = goal.target <= 0 ? 0.0 : (goal.saved / goal.target);
    return _card(
      theme,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 9,
                    color: cs.surfaceContainerHigh,
                  ),
                ),
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: cs.primary,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(goal.icon, size: 18, color: cs.primary),
                    const SizedBox(height: 2),
                    Text('${(pct * 100).round()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(goal.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
              '${_money0.format(goal.saved)} / ${_money0.format(goal.target)}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- shared
  Widget _sectionTitle(ThemeData theme, String title) => Text(
        title,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
      );

  Widget _card(ThemeData theme,
      {required Widget child, EdgeInsets? padding}) {
    final cs = theme.colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ===================================================== recent transactions
/// The five most recent transactions from the configured data source. Falls
/// back to a gentle prompt when no database is connected.
class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final async = ref.watch(dashboardDataProvider);

    final List<Expense> recent;
    if (async.hasValue) {
      final all = List<Expense>.from(async.requireValue.transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      recent = all.take(5).toList();
    } else {
      recent = const [];
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('Recent Transactions',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(navIndexProvider.notifier).select(1),
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Text(
                  async.isLoading
                      ? 'Loading transactions…'
                      : 'Connect a database in Settings to see your '
                          'recent activity.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            for (var i = 0; i < recent.length; i++)
              _row(theme, recent[i], last: i == recent.length - 1),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, Expense tx, {required bool last}) {
    final cs = theme.colorScheme;
    final isDebit = tx.debit > 0;
    final amount = tx.amount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(_fmtDate(tx.date),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (tx.source.isNotEmpty)
                  Text(tx.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 150, child: CategoryPill(category: tx.category)),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              currency2.format(amount),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDebit ? cs.error : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('d MMM yyyy').format(d);
  }
}

// ----------------------------------------------------------------- models
class _CatBudget {
  final String name;
  final IconData icon;
  final double spent;
  final double budget;
  const _CatBudget(this.name, this.icon, this.spent, this.budget);
}

class _Goal {
  final String name;
  final IconData icon;
  final double saved;
  final double target;
  const _Goal(this.name, this.icon, this.saved, this.target);
}
