import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/dashboard_provider.dart';
import '../providers/nav_provider.dart';
import '../services/database_service.dart';
import '../theme/app_ui.dart';
import '../theme/brutalism.dart';
import '../theme/typography.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/category_pill.dart' show categoryAccent;

/// One category's monthly aggregate — the result of a
/// `GROUP BY category` over the chosen month: how much was spent, how many
/// transactions made it up, and the category's name.
class _CatStat {
  final String name;
  final double total;
  final int count;
  const _CatStat(this.name, this.total, this.count);
}

/// The Summary screen: spending for a single month, grouped by category.
///
/// Conceptually it is `GROUP BY category, SUM(debit)` for the selected month.
/// The result is presented as a "spending composition" hero band (the month's
/// total broken into a single proportional bar) followed by a grid of ranked
/// category cards. A month picker in the header scopes the whole page and
/// defaults to the most recent month with data. Rendered in the app's
/// neo-brutalist style: flat fills, thick borders, hard offset shadows.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  // Selected month key ('YYYY-MM'). Null until data loads, after which it
  // defaults to the latest month present; kept here so the choice survives a
  // background data refresh.
  String? _month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(allExpensesProvider);

    final months = async.hasValue ? _monthsOf(async.requireValue) : <String>[];
    final selected = _resolveMonth(months);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            icon: Icons.summarize_rounded,
            title: 'Summary',
            subtitle: 'Spending by category for a single month.',
            trailing: months.isEmpty
                ? null
                : _MonthPicker(
                    months: months,
                    selected: selected!,
                    onChanged: (m) => setState(() => _month = m),
                  ),
          ),
          Expanded(child: _body(context, theme, async, selected)),
        ],
      ),
    );
  }

  // Distinct 'YYYY-MM' keys present in [all], newest first.
  List<String> _monthsOf(List<Expense> all) {
    final keys = <String>{};
    for (final e in all) {
      if (e.date.length >= 7) keys.add(e.date.substring(0, 7));
    }
    return keys.toList()..sort((a, b) => b.compareTo(a));
  }

  // The effective selection: the user's pick when it still exists in the data,
  // otherwise the most recent month.
  String? _resolveMonth(List<String> months) {
    if (months.isEmpty) return null;
    if (_month != null && months.contains(_month)) return _month;
    return months.first;
  }

  Widget _body(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<Expense>> async,
    String? month,
  ) {
    if (async.isLoading && !async.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (async.hasError && !async.hasValue) {
      final err = async.error;
      final noDb = err is DatabaseNotConfiguredException;
      return _message(
        context,
        theme,
        icon: noDb ? Icons.storage_rounded : Icons.error_outline_rounded,
        title: noDb ? 'No database connected' : "Couldn't load your data",
        body: noDb
            ? 'Connect a SQLite database to populate your summary.'
            : err.toString(),
        actionLabel: noDb ? 'Open Settings' : null,
      );
    }

    final all = async.requireValue;
    if (all.isEmpty || month == null) {
      return _message(
        context,
        theme,
        icon: Icons.inbox_rounded,
        title: 'No transactions yet',
        body: 'Your database has no spending to summarise.',
      );
    }

    final rows = all
        .where((e) => e.date.length >= 7 && e.date.substring(0, 7) == month)
        .toList();

    // GROUP BY category: sum debits and count contributing rows, then order
    // high-to-low so the ranking reads at a glance.
    final totals = <String, double>{};
    final counts = <String, int>{};
    double income = 0;
    for (final e in rows) {
      income += e.credit;
      if (e.debit <= 0) continue;
      totals[e.category] = (totals[e.category] ?? 0) + e.debit;
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final stats =
        [
          for (final entry in totals.entries)
            _CatStat(entry.key, entry.value, counts[entry.key] ?? 0),
        ]..sort((a, b) => b.total.compareTo(a.total));
    final expenses = stats.fold<double>(0, (s, c) => s + c.total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _hero(context, theme, month, stats, expenses, income, rows.length),
        const SizedBox(height: 24),
        AppSectionTitle(
          icon: Icons.pie_chart_rounded,
          title: 'Expenses per Category',
          subtitle: stats.isEmpty
              ? 'No spending in this month'
              : '${stats.length} categories · '
                    '${currency0.format(expenses)} total',
        ),
        const SizedBox(height: 12),
        if (stats.isEmpty)
          _emptyCategories(theme)
        else
          _categoryGrid(context, theme, stats, expenses),
      ],
    );
  }

  // --------------------------------------------------------------------- hero
  // The signature band: the month's headline figures alongside a single
  // proportional "composition" bar that splits the total into its categories.
  Widget _hero(
    BuildContext context,
    ThemeData theme,
    String month,
    List<_CatStat> stats,
    double expenses,
    double income,
    int count,
  ) {
    final cs = theme.colorScheme;
    final monthLabel = _monthLabel(month);
    final net = income - expenses;
    final green = Colors.green.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: brutalBox(cs, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final headline = _heroHeadline(theme, monthLabel, expenses, count);
              final pills = _heroPills(theme, income, net, green, cs);
              // Stack the figures above the pills when the band gets narrow so
              // nothing is squeezed.
              if (c.maxWidth < 460) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headline,
                    const SizedBox(height: 16),
                    pills,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headline),
                  const SizedBox(width: 16),
                  pills,
                ],
              );
            },
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 22),
            _compositionBar(context, stats, expenses),
            const SizedBox(height: 14),
            _compositionLegend(context, theme, stats, expenses),
          ],
        ],
      ),
    );
  }

  Widget _heroHeadline(
    ThemeData theme,
    String monthLabel,
    double expenses,
    int count,
  ) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'TOTAL SPENT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
              ),
              child: Text(
                monthLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            currency2.format(expenses),
            style: dashboardNumberStyle(
              theme.textTheme.displaySmall,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'across ${NumberFormat.decimalPattern().format(count)} '
          'transaction${count == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _heroPills(
    ThemeData theme,
    double income,
    double net,
    Color green,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _statPill(
          theme,
          'INCOMING',
          currency0.format(income),
          Icons.north_east_rounded,
          green,
        ),
        const SizedBox(height: 10),
        _statPill(
          theme,
          'NET',
          currency0.format(net),
          Icons.swap_vert_rounded,
          net >= 0 ? green : cs.error,
        ),
      ],
    );
  }

  Widget _statPill(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color accent,
  ) {
    final cs = theme.colorScheme;
    return Container(
      width: 188,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brutalLine(cs), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: brutalLine(cs), width: 1.5),
            ),
            child: Icon(icon, size: 14, color: _onAccent(accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: dashboardNumberStyle(theme.textTheme.titleSmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A single rounded, bordered bar split into one segment per category, sized
  // by its share of the month's spend. The dominant categories carry their own
  // accent; a long tail of small ones is folded into a neutral "Other" segment
  // so the bar stays readable.
  Widget _compositionBar(
    BuildContext context,
    List<_CatStat> stats,
    double total,
  ) {
    final cs = Theme.of(context).colorScheme;
    final segments = _composition(stats);
    return Container(
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brutalLine(cs), width: 1.5),
        boxShadow: [brutalShadow(cs, dx: 2, dy: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5),
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++)
              Expanded(
                flex: (segments[i].$2 / total * 10000).round().clamp(1, 1000000),
                child: Container(
                  decoration: BoxDecoration(
                    color: segments[i].$3,
                    border: i == segments.length - 1
                        ? null
                        : Border(
                            right: BorderSide(color: brutalLine(cs), width: 1.5),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _compositionLegend(
    BuildContext context,
    ThemeData theme,
    List<_CatStat> stats,
    double total,
  ) {
    final cs = theme.colorScheme;
    final segments = _composition(stats);
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final seg in segments)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: seg.$3,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: brutalLine(cs), width: 1),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                seg.$1,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                total <= 0 ? '0%' : '${(seg.$2 / total * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // The composition segments: up to the top six categories by name/total/
  // colour, with any remainder collapsed into a neutral grey "Other".
  List<(String, double, Color)> _composition(List<_CatStat> stats) {
    const maxSegments = 6;
    final shown = stats.take(maxSegments).toList();
    final segments = <(String, double, Color)>[
      for (final s in shown)
        (prettyCategory(s.name), s.total, categoryAccent(context, ref, s.name)),
    ];
    if (stats.length > maxSegments) {
      final rest = stats
          .skip(maxSegments)
          .fold<double>(0, (sum, s) => sum + s.total);
      if (rest > 0) segments.add(('Other', rest, Colors.grey.shade500));
    }
    return segments;
  }

  // --------------------------------------------------------------- categories
  Widget _categoryGrid(
    BuildContext context,
    ThemeData theme,
    List<_CatStat> stats,
    double total,
  ) {
    final maxCat = stats.first.total;
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 14.0;
        final cols = (c.maxWidth / 300).floor().clamp(1, 3);
        final w = (c.maxWidth - (cols - 1) * gap) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < stats.length; i++)
              SizedBox(
                width: w,
                child: _categoryCard(context, theme, stats[i], i, maxCat, total),
              ),
          ],
        );
      },
    );
  }

  Widget _categoryCard(
    BuildContext context,
    ThemeData theme,
    _CatStat stat,
    int rank,
    double maxCat,
    double total,
  ) {
    final cs = theme.colorScheme;
    final accent = categoryAccent(context, ref, stat.name);
    final bar = maxCat <= 0 ? 0.0 : (stat.total / maxCat);
    final share = total <= 0 ? 0.0 : (stat.total / total * 100);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: brutalBox(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brutalLine(cs), width: 1.5),
                ),
                child: Center(
                  child: FaIcon(
                    categoryIcon(stat.name),
                    size: 14,
                    color: _onAccent(accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prettyCategory(stat.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${stat.count} '
                      'transaction${stat.count == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Rank badge — the category's position in the month's ranking.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: brutalLine(cs), width: 1),
                ),
                child: Text(
                  '#${rank + 1}',
                  style: dashboardNumberStyle(theme.textTheme.labelSmall),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currency2.format(stat.total),
                style: dashboardNumberStyle(theme.textTheme.titleMedium),
              ),
              const Spacer(),
              Text(
                '${share.toStringAsFixed(0)}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent.withValues(alpha: 1),
                ),
              ),
              Text(
                ' of total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _shareBar(cs, bar, accent),
        ],
      ),
    );
  }

  // A chunky, bordered progress bar (neo-brutalist), sized relative to the top
  // category so the ranking reads at a glance.
  Widget _shareBar(ColorScheme cs, double fraction, Color accent) {
    return Container(
      height: 12,
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
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(color: accent),
          ),
        ),
      ),
    );
  }

  Widget _emptyCategories(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: brutalBox(cs),
      child: Text(
        'No expenses recorded for this month.',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }

  // ----------------------------------------------------------------- shared
  String _monthLabel(String key) {
    final dt = DateTime.tryParse('$key-01');
    return dt == null ? key : DateFormat('MMMM yyyy').format(dt);
  }

  // Black or white per the fill's brightness, so an icon stays legible whether
  // the accent is dark (light mode) or light (dark mode).
  Color _onAccent(Color accent) =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
      ? Colors.white
      : Colors.black;

  Widget _message(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String body,
    String? actionLabel,
  }) {
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
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(icon, size: 30, color: cs.onPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      ref.read(navIndexProvider.notifier).select(4),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact month dropdown for the page header, styled to match the app's
/// bordered controls. Shows months as 'June 2026'.
class _MonthPicker extends StatelessWidget {
  final List<String> months;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MonthPicker({
    required this.months,
    required this.selected,
    required this.onChanged,
  });

  String _label(String key) {
    final dt = DateTime.tryParse('$key-01');
    return dt == null ? key : DateFormat('MMMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: brutalLine(cs), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
              items: [
                for (final m in months)
                  DropdownMenuItem(value: m, child: Text(_label(m))),
              ],
              onChanged: (m) {
                if (m != null) onChanged(m);
              },
            ),
          ),
        ],
      ),
    );
  }
}
