import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../providers/filter_provider.dart';
import '../models/expense.dart';
import '../widgets/filter_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _db = DatabaseService();
  final _vScroll = ScrollController();
  final _hScroll = ScrollController();
  final _searchCtrl = TextEditingController();

  double _totalDebits = 0;
  double _totalCredits = 0;
  int _txCount = 0;
  Map<String, double> _categorySpend = {};
  List<Expense> _transactions = [];
  bool _loading = true;
  bool _loadedOnce = false;
  String? _error;
  String _section = 'transactions';
  String _query = '';

  int _page = 0;
  int _pageSize = 50;
  static const _pageSizeOptions = [25, 50, 100, 200];

  static const _chartColors = [
    Color(0xFFE57373), Color(0xFF64B5F6), Color(0xFF81C784), Color(0xFFFFD54F),
    Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFFFF8A65), Color(0xFFA1887F),
    Color(0xFF90A4AE), Color(0xFFF06292), Color(0xFF4DD0E1), Color(0xFFAED581),
    Color(0xFFFFB74D), Color(0xFF9575CD), Color(0xFF7986CB), Color(0xFF4FC3F7),
    Color(0xFFDCE775), Color(0xFFE0E0E0),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _vScroll.dispose();
    _hScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final f = ref.read(filterProvider);
      final results = await Future.wait([
        _db.getTotalDebits(filter: f),
        _db.getTotalCredits(filter: f),
        _db.getTransactionCount(filter: f),
        _db.getSpendByCategory(filter: f),
        _db.getExpenses(filter: f),
      ]);
      if (!mounted) return;
      setState(() {
        _totalDebits = results[0] as double;
        _totalCredits = results[1] as double;
        _txCount = results[2] as int;
        _categorySpend = results[3] as Map<String, double>;
        _transactions = results[4] as List<Expense>;
        _page = 0;
        _loading = false;
        _loadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadedOnce = true;
      });
    }
  }

  List<Expense> get _filtered {
    if (_query.isEmpty) return _transactions;
    final q = _query.toLowerCase();
    return _transactions
        .where((e) =>
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.source.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reload whenever the filter changes — the sidebar stays mounted so the
    // category checklist never collapses while doing so.
    ref.listen(filterProvider, (_, __) => _loadData());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        titleSpacing: 16,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'transactions',
                    label: Text('Transactions'),
                    icon: Icon(Icons.table_rows, size: 16)),
                ButtonSegment(
                    value: 'overview',
                    label: Text('Overview'),
                    icon: Icon(Icons.insights, size: 16)),
              ],
              selected: {_section},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _section = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FilterPanel(),
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_error != null) return _buildError(theme);
    if (!_loadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        SizedBox(
          height: 3,
          child: _loading ? const LinearProgressIndicator(minHeight: 3) : null,
        ),
        _buildKpiHeader(theme),
        Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
        Expanded(
          child: _section == 'overview'
              ? _buildOverview(theme)
              : _buildTransactionsView(theme),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- KPI header
  Widget _buildKpiHeader(ThemeData theme) {
    final net = _totalCredits - _totalDebits;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          _kpi(theme, 'Expenses', fmt.format(_totalDebits),
              Icons.south_west, theme.colorScheme.error),
          const SizedBox(width: 12),
          _kpi(theme, 'Income', fmt.format(_totalCredits),
              Icons.north_east, Colors.green.shade600),
          const SizedBox(width: 12),
          _kpi(theme, 'Net', fmt.format(net), Icons.account_balance_wallet,
              net >= 0 ? Colors.green.shade600 : theme.colorScheme.error),
          const SizedBox(width: 12),
          _kpi(theme, 'Transactions', NumberFormat.decimalPattern().format(_txCount),
              Icons.receipt_long, theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _kpi(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ overview
  Widget _buildOverview(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(theme, 'Spending by Category'),
        const SizedBox(height: 10),
        _buildCategoryCard(theme),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildCategoryCard(ThemeData theme) {
    if (_categorySpend.isEmpty) {
      return _emptyCard(theme, Icons.bar_chart, 'No expense data for this filter');
    }
    final entries = _categorySpend.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.18,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${entries[group.x].key.replaceAll('-', ' ')}\n',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                      children: [
                        TextSpan(
                          text: _money(rod.toY),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                barGroups: List.generate(entries.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: entries[i].value,
                      color: _chartColors[i % _chartColors.length],
                      width: 22,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ]);
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) => v == 0
                          ? const SizedBox()
                          : Text(_money(v),
                              style: const TextStyle(fontSize: 9)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: SizedBox(
                              width: 60,
                              child: Text(
                                entries[i].key.replaceAll('-', ' ').toLowerCase(),
                                style: const TextStyle(fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant, strokeWidth: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...entries.take(8).map((e) {
            final pct = total == 0 ? 0.0 : e.value / total;
            final color = _chartColors[entries.indexOf(e) % _chartColors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 10, height: 10, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.key.replaceAll('-', ' ').toLowerCase(),
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Text('${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Text(_money(e.value),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- transactions
  Widget _buildTransactionsView(ThemeData theme) {
    final all = _filtered;
    final total = all.length;
    final pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final startIndex = _page * _pageSize;
    final pageItems = all.skip(startIndex).take(_pageSize).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search description, category or bank…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _query = '';
                          _page = 0;
                        });
                      },
                    ),
              isDense: true,
            ),
            onChanged: (v) => setState(() {
              _query = v;
              _page = 0;
            }),
          ),
        ),
        Expanded(child: _buildTable(theme, pageItems, startIndex)),
        _buildPaginationBar(theme, total, startIndex, pageItems.length, pageCount),
      ],
    );
  }

  static const _columns = <(String, double, TextAlign)>[
    ('#', 56, TextAlign.left),
    ('DATE', 108, TextAlign.left),
    ('DESCRIPTION', 340, TextAlign.left),
    ('BANK', 100, TextAlign.left),
    ('AMOUNT', 120, TextAlign.right),
    ('CATEGORY', 160, TextAlign.left),
  ];

  double get _tableWidth => _columns.fold(0.0, (s, c) => s + c.$2) + 32;

  Widget _buildTable(ThemeData theme, List<Expense> list, int startIndex) {
    if (list.isEmpty) {
      return _emptyCenter(theme, Icons.search_off, 'No transactions match');
    }
    return LayoutBuilder(builder: (context, constraints) {
      final width =
          _tableWidth < constraints.maxWidth ? constraints.maxWidth : _tableWidth;
      return Scrollbar(
        controller: _hScroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _hScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                _tableHeader(theme),
                Expanded(
                  child: Scrollbar(
                    controller: _vScroll,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _vScroll,
                      itemCount: list.length,
                      itemExtent: 44,
                      itemBuilder: (context, i) =>
                          _tableRow(theme, list[i], startIndex + i, i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _tableHeader(ThemeData theme) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Row(
        children: _columns
            .map((c) => SizedBox(
                  width: c.$2,
                  child: Text(c.$1,
                      textAlign: c.$3,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onPrimary)),
                ))
            .toList(),
      ),
    );
  }

  Widget _tableRow(ThemeData theme, Expense tx, int displayIndex, int rowInPage) {
    final amount = tx.debit > 0 ? -tx.debit : tx.credit;
    final isDebit = tx.debit > 0;
    final values = <String>[
      '${displayIndex + 1}',
      tx.date,
      tx.description,
      tx.source,
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
      tx.category.replaceAll('-', ' ').toLowerCase(),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: rowInPage.isOdd ? theme.colorScheme.surfaceContainerLow : null,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: List.generate(_columns.length, (c) {
          final isAmount = c == 4;
          return SizedBox(
            width: _columns[c].$2,
            child: Text(
              values[c],
              textAlign: _columns[c].$3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isAmount ? FontWeight.w800 : FontWeight.w500,
                color: isAmount
                    ? (isDebit ? theme.colorScheme.error : Colors.green.shade700)
                    : theme.colorScheme.onSurface,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaginationBar(
      ThemeData theme, int total, int startIndex, int shown, int pageCount) {
    final from = total == 0 ? 0 : startIndex + 1;
    final to = startIndex + shown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text('Rows per page', style: theme.textTheme.labelSmall),
          const SizedBox(width: 10),
          DropdownButton<int>(
            value: _pageSize,
            isDense: true,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: _pageSizeOptions
                .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text('$n',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700))))
                .toList(),
            onChanged: (v) => v == null
                ? null
                : setState(() {
                    _pageSize = v;
                    _page = 0;
                  }),
          ),
          const Spacer(),
          Text('$from–$to of $total',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          IconButton.outlined(
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Previous',
            style: IconButton.styleFrom(
                minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
          ),
          const SizedBox(width: 6),
          Text('${_page + 1} / $pageCount',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          IconButton.outlined(
            onPressed:
                _page < pageCount - 1 ? () => setState(() => _page++) : null,
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Next',
            style: IconButton.styleFrom(
                minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- helpers
  String _money(double v) {
    if (v.abs() >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
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

  Widget _emptyCenter(ThemeData theme, IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(msg, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load data', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
