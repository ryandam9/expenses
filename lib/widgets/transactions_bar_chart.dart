import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../utils/format.dart';
import 'category_pill.dart';

/// One bar per transaction — date on X, amount on Y — for the category
/// explorer. Bars take their category's stable accent colour, so a
/// multi-category selection reads at a glance (a small legend appears when
/// more than one category is charted). With few bars the amounts are
/// labelled permanently; with many, hover tooltips show date, description
/// and amount instead.
class TransactionsBarChart extends ConsumerStatefulWidget {
  final List<Expense> transactions;
  const TransactionsBarChart({super.key, required this.transactions});

  /// Keeps very large selections responsive: only the most recent bars are
  /// drawn beyond this count.
  static const _maxBars = 500;

  @override
  ConsumerState<TransactionsBarChart> createState() =>
      _TransactionsBarChartState();
}

class _TransactionsBarChartState extends ConsumerState<TransactionsBarChart> {
  // Shared between the Scrollbar and the scroll view — without this the
  // thumb renders but dragging it does nothing.
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Spending only, oldest to newest left-to-right.
    var rows = widget.transactions.where((e) => e.debit > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final totalCount = rows.length;
    if (rows.length > TransactionsBarChart._maxBars) {
      rows = rows.sublist(rows.length - TransactionsBarChart._maxBars);
    }

    final title = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.18),
                cs.tertiary.withValues(alpha: 0.14),
              ],
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.bar_chart, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text('Individual Transactions',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        const SizedBox(width: 10),
        if (totalCount > rows.length)
          Text('latest ${rows.length} of $totalCount',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );

    if (rows.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, color: cs.outline),
                const SizedBox(width: 12),
                Text('No expense transactions in this selection',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    final maxVal =
        rows.map((e) => e.debit).reduce((a, b) => a > b ? a : b);
    final few = rows.length <= 20;
    // Generous headroom so the value labels / hover tooltips never collide
    // with the top of the chart.
    final maxY = maxVal <= 0 ? 1.0 : maxVal * (few ? 1.3 : 1.25);
    final slotWidth = few ? 44.0 : 26.0;
    final barWidth = few ? 24.0 : 14.0;
    final minChartWidth = rows.length * slotWidth;
    final labelStep = (rows.length / 8).ceil().clamp(1, rows.length);
    final multiYear = rows.first.date.length >= 4 &&
        rows.last.date.length >= 4 &&
        rows.first.date.substring(0, 4) != rows.last.date.substring(0, 4);

    final colors = [
      for (final e in rows) categoryAccent(context, ref, e.category)
    ];
    final chartedCategories = rows.map((e) => e.category).toSet().toList()
      ..sort();

    String xLabel(String iso) {
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return DateFormat(multiYear ? 'd/M/yy' : 'd MMM').format(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 18, 18, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceContainerLowest,
                Color.alphaBlend(cs.primary.withValues(alpha: 0.04),
                    cs.surfaceContainerLowest),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant, width: 1),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chartedCategories.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final c in chartedCategories)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: categoryAccent(context, ref, c),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(prettyCategory(c),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Semantics(
                label:
                    'Bar chart of ${rows.length} individual transactions over time',
                child: SizedBox(
                  height: 430,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final width = minChartWidth < c.maxWidth
                          ? c.maxWidth
                          : minChartWidth;
                      return Scrollbar(
                        controller: _hScroll,
                        thumbVisibility: minChartWidth > c.maxWidth,
                        child: SingleChildScrollView(
                          controller: _hScroll,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: width,
                            child: BarChart(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxY,
                                barTouchData: few
                                    // Few bars: permanent value labels via the
                                    // transparent-tooltip technique.
                                    ? BarTouchData(
                                        enabled: false,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (_) =>
                                              Colors.transparent,
                                          tooltipPadding: EdgeInsets.zero,
                                          tooltipMargin: 6,
                                          fitInsideVertically: true,
                                          fitInsideHorizontally: true,
                                          getTooltipItem: (group, _, rod, _) =>
                                              BarTooltipItem(
                                            compactMoney(rod.toY),
                                            TextStyle(
                                                color: cs.onSurface,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10.5),
                                          ),
                                        ),
                                      )
                                    // Many bars: hover for the detail.
                                    : BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          // Reposition tooltips that would
                                          // poke past the chart's edges.
                                          fitInsideVertically: true,
                                          fitInsideHorizontally: true,
                                          getTooltipItem: (group, _, rod, _) {
                                            final e = rows[group.x];
                                            final desc = e.description.length >
                                                    36
                                                ? '${e.description.substring(0, 35)}…'
                                                : e.description;
                                            return BarTooltipItem(
                                              '${xLabel(e.date)}\n',
                                              const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11),
                                              children: [
                                                TextSpan(
                                                  text: '$desc\n',
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 10),
                                                ),
                                                TextSpan(
                                                  text: currency2
                                                      .format(e.debit),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 11),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                barGroups: [
                                  for (var i = 0; i < rows.length; i++)
                                    BarChartGroupData(
                                      x: i,
                                      showingTooltipIndicators:
                                          few ? const [0] : const [],
                                      barRods: [
                                        BarChartRodData(
                                          toY: rows[i].debit,
                                          width: barWidth,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(5)),
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              colors[i]
                                                  .withValues(alpha: 0.72),
                                              colors[i],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 46,
                                      getTitlesWidget: (v, _) => v == 0
                                          ? const SizedBox()
                                          : Text(compactMoney(v),
                                              style: const TextStyle(
                                                  fontSize: 9)),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: 1,
                                      getTitlesWidget: (v, _) {
                                        final i = v.toInt();
                                        if (i < 0 ||
                                            i >= rows.length ||
                                            i % labelStep != 0) {
                                          return const SizedBox();
                                        }
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(xLabel(rows[i].date),
                                              style: const TextStyle(
                                                  fontSize: 9)),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval:
                                      maxVal <= 0 ? 1 : maxVal / 4,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                      color: cs.outlineVariant,
                                      strokeWidth: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
