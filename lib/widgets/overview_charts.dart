import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/theme_provider.dart';
import '../services/query_builder.dart';
import '../theme/app_themes.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';

/// The Overview section: spending-over-time trend, per-category bar chart and
/// category share donut. All aggregates are computed from [transactions] — the
/// exact rows on screen — so they always agree with the table and any active
/// search. Hosts can prepend [leading] widgets to the scroll view and drop the
/// per-category bar chart via [showCategoryBar] (the category explorer leads
/// with its own per-transaction chart instead).
class OverviewCharts extends ConsumerStatefulWidget {
  final List<Expense> transactions;
  final bool showCategoryBar;
  final List<Widget> leading;
  const OverviewCharts({
    super.key,
    required this.transactions,
    this.showCategoryBar = true,
    this.leading = const [],
  });

  @override
  ConsumerState<OverviewCharts> createState() => _OverviewChartsState();
}

class _OverviewChartsState extends ConsumerState<OverviewCharts> {
  // Index of the donut slice currently highlighted (-1 = none). Set by
  // hovering either the donut itself or its legend rows, and drives the slice
  // "pop", the legend row tint and the live readout in the donut's centre.
  int _touchedPie = -1;

  // Shared implicit-animation settings for all fl_chart widgets, so charts
  // ease into place on load and morph smoothly when the filter changes.
  static const _chartAnim = Duration(milliseconds: 500);
  static const _chartCurve = Curves.easeOutCubic;

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
        ...widget.leading,
        _sectionTitle(theme, Icons.show_chart, 'Spending Over Time'),
        const SizedBox(height: 10),
        _buildTrendCard(theme),
        const SizedBox(height: 24),
        if (widget.showCategoryBar) ...[
          _sectionTitle(theme, Icons.bar_chart, 'Spending by Category'),
          const SizedBox(height: 10),
          _buildCategoryBarCard(theme),
          const SizedBox(height: 24),
        ],
        _sectionTitle(theme, Icons.donut_large, 'Category Share'),
        const SizedBox(height: 10),
        _buildCategoryCard(theme),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    final cs = theme.colorScheme;
    return Row(
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
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2)),
      ],
    );
  }

  /// Card chrome shared by every chart: a faintly primary-tinted surface with
  /// a soft drop shadow so the cards lift off the ambient background instead
  /// of sitting flat on it.
  BoxDecoration _cardDecoration(ThemeData theme) {
    final cs = theme.colorScheme;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          cs.surfaceContainerLowest,
          Color.alphaBlend(
              cs.primary.withValues(alpha: 0.04), cs.surfaceContainerLowest),
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
    );
  }

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

  /// Small labelled figure ("AVG / MONTH  $1.2k") for the trend card header.
  Widget _miniStat(ThemeData theme, String label, String value) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
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
    final avgSpend = totalSpend / series.length;
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].value)
    ];
    final lineColor = cs.primary;
    final labelStep = (series.length / 6).ceil().clamp(1, series.length);
    final periodWord = monthly ? 'month' : 'day';

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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('total spend · by $periodWord',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
              ),
              _miniStat(theme, 'avg / $periodWord', compactMoney(avgSpend)),
              const SizedBox(width: 8),
              _miniStat(theme, 'peak $periodWord', compactMoney(maxY)),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            label: 'Line chart of spending over time, total '
                '${compactMoney(totalSpend)}',
            child: SizedBox(
              height: 260,
              child: LineChart(
                duration: _chartAnim,
                curve: _chartCurve,
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
                      // A primary→tertiary sweep gives the line more life than
                      // a flat single colour.
                      gradient: LinearGradient(
                        colors: [lineColor, cs.tertiary],
                      ),
                      barWidth: 3.5,
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
  // glance; bars take the category's own colour from the chart palette. The
  // chart always fills the card's full width; when there are too many
  // categories to fit comfortably it grows and scrolls horizontally instead
  // of squeezing the bars.
  Widget _buildCategoryBarCard(ThemeData theme) {
    final cs = theme.colorScheme;
    final byCategory = debitTotalsBy(widget.transactions, (e) => e.category);
    if (byCategory.isEmpty) {
      return _emptyCard(theme, Icons.bar_chart, 'No expense data for this filter');
    }
    final entries = byCategory.entries.toList();
    final maxVal = entries.first.value;
    final colors = _colors(entries.length);
    // Extra headroom so the always-on value labels above the bars never clip.
    final maxY = maxVal <= 0 ? 1.0 : maxVal * 1.22;
    // Minimum room per category: a fat bar plus an un-truncated two-line
    // label underneath.
    const slotWidth = 104.0;
    final minChartWidth = entries.length * slotWidth;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 18, 12),
      decoration: _cardDecoration(theme),
      child: Semantics(
        label: 'Bar chart of total spending by category',
        child: SizedBox(
          height: 380,
          child: LayoutBuilder(
            builder: (context, c) {
              final width =
                  minChartWidth < c.maxWidth ? c.maxWidth : minChartWidth;
              return Scrollbar(
                thumbVisibility: minChartWidth > c.maxWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: BarChart(
                      duration: _chartAnim,
                      curve: _chartCurve,
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        // Values are rendered permanently above each bar using
                        // the transparent-tooltip technique, so the chart reads
                        // at a glance without hovering.
                        barTouchData: BarTouchData(
                          enabled: false,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.transparent,
                            tooltipPadding: EdgeInsets.zero,
                            tooltipMargin: 6,
                            getTooltipItem: (group, _, rod, _) =>
                                BarTooltipItem(
                              compactMoney(rod.toY),
                              TextStyle(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11),
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < entries.length; i++)
                            BarChartGroupData(
                                x: i,
                                showingTooltipIndicators: const [0],
                                barRods: [
                                  BarChartRodData(
                                    toY: entries[i].value,
                                    width: 46,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        colors[i].withValues(alpha: 0.72),
                                        colors[i],
                                      ],
                                    ),
                                    backDrawRodData:
                                        BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxY,
                                      color: cs.surfaceContainerHigh
                                          .withValues(alpha: 0.45),
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
                              reservedSize: 44,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= entries.length) {
                                  return const SizedBox();
                                }
                                // Horizontal, two-line labels: with a full
                                // slot's width available, names render whole
                                // instead of rotated and clipped.
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    width: slotWidth - 8,
                                    child: Text(
                                      prettyCategory(entries[i].key),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          height: 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
        width: 340,
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              duration: _chartAnim,
              curve: _chartCurve,
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 86,
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
                      radius: _touchedPie == i ? 72 : 62,
                      // Label the slices big enough to fit a readable
                      // percentage; thin slivers stay clean and rely on the
                      // legend instead.
                      showTitle: total > 0 && entries[i].value / total >= 0.05,
                      title:
                          '${(entries[i].value / total * 100).round()}%',
                      titlePositionPercentageOffset: 0.62,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 2, color: Colors.black38),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Centre readout: hovering a slice (or legend row) swaps the
            // grand total for that category's share and amount.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _touchedPie >= 0 && _touchedPie < entries.length
                      ? compactMoney(entries[_touchedPie].value)
                      : compactMoney(total),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  _touchedPie >= 0 && _touchedPie < entries.length
                      ? '${prettyCategory(entries[_touchedPie].key)} '
                          '· ${(entries[_touchedPie].value / total * 100).toStringAsFixed(1)}%'
                      : 'total',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium
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
          if (c.maxWidth < 680) {
            return Column(
              children: [donut, const SizedBox(height: 16), legend],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              donut,
              const SizedBox(width: 28),
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
    // Hovering a row highlights the matching donut slice (and vice versa), so
    // the two halves of the card read as one linked visualisation.
    return MouseRegion(
      onEnter: (_) => setState(() => _touchedPie = i),
      onExit: (_) => setState(() {
        if (_touchedPie == i) _touchedPie = -1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // The category's icon in a chip tinted with its slice colour, so
            // the legend still keys rows to slices while reading richer.
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: active ? 0.28 : 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: FaIcon(categoryIcon(e.key), size: 12, color: color),
              ),
            ),
            const SizedBox(width: 10),
            // Fixed-width name keeps every bar starting on the same axis,
            // right next to the label instead of across a wide gap.
            SizedBox(
              width: 148,
              child: Text(prettyCategory(e.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            ),
            const SizedBox(width: 12),
            // The share bar takes all remaining width, so the amount each
            // category represents is the dominant visual in the row.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  backgroundColor: cs.surfaceContainerHigh,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 76,
              child: Text(compactMoney(e.value),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 50,
              child: Text('${(pct * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
