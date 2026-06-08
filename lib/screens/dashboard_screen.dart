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
  final _scrollCtrl = ScrollController();
  final _searchCtrl = SearchController();

  double _totalDebits = 0;
  double _totalCredits = 0;
  int _txCount = 0;
  Map<String, double> _categorySpend = {};
  List<Expense> _transactions = [];
  bool _loading = true;
  String? _error;
  String _section = 'overview';

  int _page = 0;
  int _pageSize = 50;
  static const _pageSizeOptions = [25, 50, 100, 200];

  static const _chartColors = [
    Color(0xFFE57373),
    Color(0xFF64B5F6),
    Color(0xFF81C784),
    Color(0xFFFFD54F),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFFF8A65),
    Color(0xFFA1887F),
    Color(0xFF90A4AE),
    Color(0xFFF06292),
    Color(0xFF4DD0E1),
    Color(0xFFAED581),
    Color(0xFFFFB74D),
    Color(0xFF9575CD),
    Color(0xFF7986CB),
    Color(0xFF4FC3F7),
    Color(0xFFDCE775),
    Color(0xFFE0E0E0),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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

      setState(() {
        _totalDebits = results[0] as double;
        _totalCredits = results[1] as double;
        _txCount = results[2] as int;
        _categorySpend = results[3] as Map<String, double>;
        _transactions = results[4] as List<Expense>;
        _page = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Expense> _filteredTx(String query) {
    if (query.isEmpty) return _transactions;
    final q = query.toLowerCase();
    return _transactions.where((e) {
      return e.description.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.source.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider);
    ref.listen(filterProvider, (_, _) => _loadData());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'overview', label: Text('Overview')),
                ButtonSegment(value: 'transactions', label: Text('Transactions')),
              ],
              selected: {_section},
              onSelectionChanged: (s) => setState(() => _section = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator.adaptive())
          : _error != null
              ? _buildError(theme)
              : Column(
                  children: [
                    if (filter.hasPeriod) _buildPeriodBadge(theme),
                    const FilterBar(),
                    Expanded(
                      child: _section == 'overview'
                          ? _buildOverview(theme)
                          : _buildTransactionsView(theme),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPeriodBadge(ThemeData theme) {
    final notifier = ref.read(filterProvider.notifier);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            notifier.periodLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => ref.read(filterProvider.notifier).setRange(null, null),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
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
            Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
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

  Widget _buildOverview(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryRow(theme),
          const SizedBox(height: 24),
          _sectionTitle('Spending by Category', theme),
          const SizedBox(height: 8),
          _buildCategoryBarChart(theme),
          const SizedBox(height: 24),
          _sectionTitle('Recent Transactions', theme),
          const SizedBox(height: 8),
          _buildRecentTable(theme),
        ],
      ),
    );
  }

  Widget _buildTransactionsView(ThemeData theme) {
    final all = _filteredTx(_searchCtrl.text);
    final total = all.length;
    final pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final startIndex = _page * _pageSize;
    final pageItems = all.skip(startIndex).take(_pageSize).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SearchAnchor(
            searchController: _searchCtrl,
            builder: (context, controller) {
              return SearchBar(
                controller: controller,
                hintText: 'Search transactions...',
                leading: const Icon(Icons.search, size: 20),
                trailing: [
                  if (controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    ),
                ],
                onTap: () => controller.openView(),
                onChanged: (_) => setState(() => _page = 0),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              );
            },
            suggestionsBuilder: (context, controller) {
              final q = controller.text.toLowerCase();
              final results = _filteredTx(q).take(10);
              return results.map((tx) {
                return ListTile(
                  dense: true,
                  title: Text(tx.description, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    '${tx.date} · ${tx.category.replaceAll('-', ' ').toLowerCase()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Text(
                    NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                        .format(tx.debit > 0 ? -tx.debit : tx.credit),
                    style: TextStyle(
                      fontSize: 11,
                      color: tx.debit > 0 ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  onTap: () {
                    controller.closeView(tx.description);
                    setState(() {});
                  },
                );
              });
            },
          ),
        ),
        Expanded(
          child: _buildTransactionTable(theme, pageItems, startIndex),
        ),
        _buildPaginationBar(theme, total, startIndex, pageItems.length, pageCount),
      ],
    );
  }

  Widget _buildPaginationBar(
      ThemeData theme, int total, int startIndex, int shown, int pageCount) {
    final from = total == 0 ? 0 : startIndex + 1;
    final to = startIndex + shown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 2),
        ),
      ),
      child: Row(
        children: [
          Text('Rows:', style: theme.textTheme.labelSmall),
          const SizedBox(width: 8),
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
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() {
                _pageSize = v;
                _page = 0;
              });
            },
          ),
          const Spacer(),
          Text(
            '$from–$to of $total',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Previous',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${_page + 1}/$pageCount',
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          IconButton.outlined(
            onPressed: _page < pageCount - 1 ? () => setState(() => _page++) : null,
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Next',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // Column layout shared by the header and data rows so they stay aligned.
  static const _columns = <(String, double, TextAlign)>[
    ('#', 52, TextAlign.left),
    ('DATE', 104, TextAlign.left),
    ('DESCRIPTION', 320, TextAlign.left),
    ('BANK', 96, TextAlign.left),
    ('AMOUNT', 112, TextAlign.right),
    ('CATEGORY', 150, TextAlign.left),
  ];

  double get _tableWidth =>
      _columns.fold(0.0, (sum, c) => sum + c.$2) + 24;

  Widget _buildTransactionTable(ThemeData theme, List<Expense> list, int startIndex) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No transactions match', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }
    return Scrollbar(
      controller: _scrollCtrl,
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            children: [
              _tableHeader(theme),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemExtent: 40,
                  itemBuilder: (context, i) =>
                      _tableRow(theme, list[i], startIndex + i, i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(ThemeData theme) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 2),
        ),
      ),
      child: Row(
        children: _columns.map((c) {
          return SizedBox(
            width: c.$2,
            child: Text(
              c.$1,
              textAlign: c.$3,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tableRow(ThemeData theme, Expense tx, int displayIndex, int rowInPage) {
    final amount = tx.debit > 0 ? -tx.debit : tx.credit;
    final values = <String>[
      '${displayIndex + 1}',
      tx.date,
      tx.description,
      tx.source,
      NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
      tx.category.replaceAll('-', ' ').toLowerCase(),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: rowInPage.isOdd ? theme.colorScheme.surfaceContainerLow : null,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
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
                fontSize: 12,
                fontWeight: isAmount ? FontWeight.w700 : FontWeight.w500,
                color: isAmount
                    ? (tx.debit > 0 ? theme.colorScheme.error : Colors.green.shade700)
                    : theme.colorScheme.onSurface,
              ),
            ),
          );
        }),
      ),
    );
  }

  DataColumn _col(String label, double width) {
    return DataColumn(
      label: SizedBox(
        width: width,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  DataCell _cell(String text, double width) {
    return DataCell(SizedBox(
      width: width,
      child: Text(text, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
    ));
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Expenses',
            value: fmt.format(_totalDebits),
            icon: Icons.trending_up,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Income',
            value: fmt.format(_totalCredits),
            icon: Icons.trending_down,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Transactions',
            value: NumberFormat.compact().format(_txCount),
            icon: Icons.receipt_long,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCategoryBarChart(ThemeData theme) {
    if (_categorySpend.isEmpty) {
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              const Text('No expense data'),
            ],
          ),
        ),
      );
    }

    final entries = _categorySpend.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.15,
                  barGroups: List.generate(entries.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value,
                          color: _chartColors[i % _chartColors.length],
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, _) {
                          if (value == 0) return const SizedBox();
                          return Text(_formatAmount(value), style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= entries.length) return const SizedBox();
                          final label = _shortLabel(entries[i].key);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxVal / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortLabel(String label) {
    final words = label.split('-');
    if (words.length > 1) {
      return words.map((w) => w.isNotEmpty ? w[0].toLowerCase() : '').join();
    }
    return label.length > 8 ? label.substring(0, 8) : label.toLowerCase();
  }

  String _formatAmount(double val) {
    if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(0)}k';
    return '\$${val.toStringAsFixed(0)}';
  }

  Widget _buildRecentTable(ThemeData theme) {
    final list = _transactions.take(20).toList();
    if (list.isEmpty) {
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              const Text('No transactions found'),
            ],
          ),
        ),
      );
    }

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 0,
          headingRowHeight: 36,
          dataRowMinHeight: 30,
          dataRowMaxHeight: 36,
          horizontalMargin: 8,
          border: TableBorder(
            horizontalInside: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
          columns: [
            _col('#', 40),
            _col('DATE', 96),
            _col('TXN DESCRIPTION', 300),
            _col('BANK', 80),
            _col('AMOUNT', 90),
            _col('CATEGORY', 120),
          ],
          rows: List.generate(list.length, (i) {
            final tx = list[i];
            final amount = tx.debit > 0 ? -tx.debit : tx.credit;
            return DataRow(
              color: WidgetStateProperty.resolveWith((_) {
                if (i.isOdd) return theme.colorScheme.surfaceContainerLow;
                return null;
              }),
              cells: [
                _cell('${i + 1}', 40),
                _cell(tx.date, 96),
                _cell(tx.description, 300),
                _cell(tx.source, 80),
                DataCell(SizedBox(
                  width: 90,
                  child: Text(
                    NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: tx.debit > 0 ? theme.colorScheme.error : Colors.green.shade700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                )),
                _cell(tx.category.replaceAll('-', ' ').toLowerCase(), 120),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ink, width: 2.5),
        boxShadow: [
          BoxShadow(color: ink, offset: const Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
