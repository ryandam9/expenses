import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/theme_provider.dart';
import '../services/query_builder.dart';
import '../theme/app_themes.dart';
import '../utils/format.dart';

/// The Overview section: spending-over-time trend, per-category bar chart,
/// per-bank breakdown and category share donut. All aggregates are computed
/// from [transactions] — the exact rows on screen — so they always agree with
/// the table and any active search.
class OverviewCharts extends ConsumerStatefulWidget {
  final List<Expense> transactions;
  const OverviewCharts({super.key, required this.transactions});

  @override
  ConsumerState<OverviewCharts> createState() => _OverviewChartsState();
}

class _OverviewChartsState extends ConsumerState<OverviewCharts> {
  // Index of the donut slice currently under the pointer (-1 = none). Drives
  // the slice "pop" and the live readout in the donut's centre.
  int _touchedPie = -1;

  /// Chart colours drawn from the active theme's chart palette, so the
  /// visualisations share the rest of the app's colour identity.
  List<Color> _colors(int n) {
    final palette = appThemes[ref.watch(themeIndexProvider)].palette;
    final colors = buildChartColors(palette, n);
    return colors.isEmpty ? List.filled(n, Colors.grey) : colors;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(theme, 'Spending Over Time'),
        const SizedBox(height: 10),
        _buildTrendCard(theme),
        const SizedBox(height: 24),
        _sectionTitle(theme, 'Spending by Category'),
        const SizedBox(height: 10),
        _buildCategoryBarCard(theme),
        const SizedBox(height: 24),
        _sectionTitle(theme, 'Spending by Bank'),
        const SizedBox(height: 10),
        _buildBankCard(theme),
        const SizedBox(height: 24),
        _sectionTitle(theme, 'Category Share'),
        const SizedBox(height: 10),
        _buildCategoryCard(theme),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) => BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      );

  Widget _emptyCard(ThemeData theme, IconData icon, String msg) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Text(msg, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- trend
  // Aggregates expenses (debits) into an ordered time series. Spans wider than
  // ~two months collapse to one point per calendar month so the axis stays
  // legible; shorter spans keep per-day resolution.
  (List<MapEntry<String, double>>, bool) _trendSeries() {
    final distinctDays = <String>{};
    for (final e in widget.transactions) {
      if (e.debit > 0) distinctDays.add(e.date);
    }
    final monthly = distinctDays.length > 62;
    final byKey = <String, double>{};
    for (final e in widget.transactions) {
      if (e.debit <= 0) continue;
      final d = e.date;
      final key = monthly ? (d.length >= 7 ? d.substring(0, 7) : d) : d;
      byKey[key] = (byKey[key] ?? 0) + e.debit;
    }
    final entries = byKey.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return (entries, monthly);
  }

  String _trendLabel(String key, bool monthly, {bool full = false}) {
    final dt = DateTime.tryParse(monthly ? '$key-01' : key);
    if (dt == null) return key;
    if (monthly) return DateFormat(full ? 'MMM yyyy' : 'MMM').format(dt);
    return DateFormat(full ? 'd MMM yyyy' : 'd/M').format(dt);
  }

  Widget _buildTrendCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final (series, monthly) = _trendSeries();
    if (series.isEmpty) {
      return _emptyCard(theme, Icons.show_chart, 'No expense data for this filter');
    }
    final maxY = series.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final totalSpend = series.fold<double>(0, (s, e) => s + e.value);
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].value)
    ];
    final lineColor = cs.primary;
    final labelStep = (series.length / 6).ceil().clamp(1, series.length);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 14),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(compactMoney(totalSpend),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('total spend · ${monthly ? 'by month' : 'by day'}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            label: 'Line chart of spending over time, total '
                '${compactMoney(totalSpend)}',
            child: SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 1 : maxY * 1.15,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => touched.map((t) {
                        final e = series[t.x.toInt()];
                        return LineTooltipItem(
                          '${_trendLabel(e.key, monthly, full: true)}\n',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                          children: [
                            TextSpan(
                              text: compactMoney(e.value),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      preventCurveOverShooting: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: series.length <= 31,
                        getDotPainter: (s, _, _, _) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: lineColor,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withValues(alpha: 0.28),
                            lineColor.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
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
                                style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= series.length) {
                            return const SizedBox();
                          }
                          if (i % labelStep != 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_trendLabel(series[i].key, monthly),
                                style: const TextStyle(fontSize: 9)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- category bar
  // A straightforward bar chart: one bar per category (X) sized by its total
  // spend (Y). Categories are ordered high-to-low so the ranking reads at a
  // glance; bars take the category's own colour from the chart palette.
  Widget _buildCategoryBarCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final byCategory = debitTotalsBy(widget.transactions, (e) => e.category);
    if (byCategory.isEmpty) {
      return _emptyCard(theme, Icons.bar_chart, 'No expense data for this filter');
    }
    final entries = byCategory.entries.toList();
    final maxVal = entries.first.value;
    final colors = _colors(entries.length);
    // Keep bars readable: give each one breathing room and let the card scroll
    // horizontally when there are many categories.
    final chartWidth = (entries.length * 56).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 16, 8),
      decoration: _cardDecoration(theme),
      child: Semantics(
        label: 'Bar chart of total spending by category',
        child: SizedBox(
          height: 300,
          child: LayoutBuilder(
            builder: (context, c) {
              final width = chartWidth < c.maxWidth ? c.maxWidth : chartWidth;
              return Scrollbar(
                thumbVisibility: chartWidth > c.maxWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxVal <= 0 ? 1 : maxVal * 1.18,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, _, rod, _) =>
                                BarTooltipItem(
                              '${entries[group.x].key.replaceAll('-', ' ')}\n',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11),
                              children: [
                                TextSpan(
                                  text: compactMoney(rod.toY),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < entries.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: entries[i].value,
                                width: 24,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6)),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    colors[i].withValues(alpha: 0.75),
                                    colors[i],
                                  ],
                                ),
                              ),
                            ]),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              getTitlesWidget: (v, _) => v == 0
                                  ? const SizedBox()
                                  : Text(compactMoney(v),
                                      style: const TextStyle(fontSize: 9)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= entries.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: SizedBox(
                                      width: 58,
                                      child: Text(
                                        entries[i]
                                            .key
                                            .replaceAll('-', ' ')
                                            .toLowerCase(),
                                        style: const TextStyle(fontSize: 8.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxVal <= 0 ? 1 : maxVal / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                              color: cs.outlineVariant, strokeWidth: 0.5),
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
    );
  }

  // --------------------------------------------------------------------- bank
  // Horizontal bars, one per bank/source, sized relative to the biggest
  // spender. Simple rows rather than a chart: with a handful of banks this is
  // easier to read and to select/copy from.
  Widget _buildBankCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final bySource = debitTotalsBy(widget.transactions, (e) => e.source);
    if (bySource.isEmpty) {
      return _emptyCard(
          theme, Icons.account_balance, 'No expense data for this filter');
    }
    final entries = bySource.entries.toList();
    final maxVal = entries.first.value;
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = _colors(entries.length);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(theme),
      child: Semantics(
        label: 'Spending by bank, total ${compactMoney(total)}',
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(entries[i].key,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Stack(
                            children: [
                              Container(
                                  height: 18, color: cs.surfaceContainerHigh),
                              FractionallySizedBox(
                                widthFactor: maxVal <= 0
                                    ? 0
                                    : (entries[i].value / maxVal)
                                        .clamp(0.0, 1.0),
                                child: Container(
                                    height: 18, color: colors[i]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 70,
                        child: Text(compactMoney(entries[i].value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        child: Text(
                            total == 0
                                ? '—'
                                : '${(entries[i].value / total * 100).toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- donut
  Widget _buildCategoryCard(ThemeData theme) {
    final byCategory = debitTotalsBy(widget.transactions, (e) => e.category);
    if (byCategory.isEmpty) {
      return _emptyCard(
          theme, Icons.donut_large, 'No expense data for this filter');
    }
    final entries = byCategory.entries.toList();
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final colors = _colors(entries.length);

    final donut = Semantics(
      label: 'Donut chart of category share, total ${compactMoney(total)}',
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 62,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  touchCallback: (event, resp) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          resp == null ||
                          resp.touchedSection == null) {
                        _touchedPie = -1;
                      } else {
                        _touchedPie = resp.touchedSection!.touchedSectionIndex;
                      }
                    });
                  },
                ),
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value,
                      color: colors[i],
                      radius: _touchedPie == i ? 30 : 24,
                      showTitle: false,
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _touchedPie >= 0 && _touchedPie < entries.length
                      ? '${(entries[_touchedPie].value / total * 100).toStringAsFixed(1)}%'
                      : compactMoney(total),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  _touchedPie >= 0 && _touchedPie < entries.length
                      ? entries[_touchedPie]
                          .key
                          .replaceAll('-', ' ')
                          .toLowerCase()
                      : 'total',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final legend = SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++)
            _legendRow(theme, entries[i], colors[i], total, i),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(theme),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 560) {
            return Column(
              children: [donut, const SizedBox(height: 16), legend],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              donut,
              const SizedBox(width: 24),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }

  Widget _legendRow(ThemeData theme, MapEntry<String, double> e, Color color,
      double total, int i) {
    final cs = theme.colorScheme;
    final pct = total == 0 ? 0.0 : e.value / total;
    final active = _touchedPie == i;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.key.replaceAll('-', ' ').toLowerCase(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHigh,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${(pct * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(compactMoney(e.value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
