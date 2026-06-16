import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../providers/category_explorer_provider.dart';
import '../services/database_service.dart';
import '../theme/app_ui.dart';
import '../theme/brutalism.dart';
import '../theme/typography.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';
import '../widgets/category_pill.dart';
import '../widgets/overview_charts.dart';
import '../widgets/transactions_bar_chart.dart';

/// Category-first exploration: pick one or more categories from the entire
/// database and see all their transactions across all time, optionally
/// narrowed to a date range. Completely independent of the dashboard's
/// period-first filters.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _section = 'transactions';

  // Free-text search over the transactions table (description only).
  final _txSearchCtrl = TextEditingController();
  String _txSearch = '';

  // Category list order: alphabetical by default, or by all-time spend.
  bool _sortAlpha = true;

  // Transactions table sort.
  String _sortKey = 'date';
  bool _sortAsc = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _txSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppPageHeader(
            icon: Icons.category_rounded,
            title: 'Categories',
            subtitle: 'Explore spending by category across your entire history',
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCategoryPanel(theme),
                Expanded(child: _buildResults(theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- category list
  Widget _buildCategoryPanel(ThemeData theme) {
    final cs = theme.colorScheme;
    final summariesAsync = ref.watch(categorySummariesProvider);
    final state = ref.watch(categoryExplorerProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.72),
        border: Border(right: BorderSide(color: brutalLine(cs), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search categories…',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
            child: Row(
              children: [
                Text(
                  state.selected.isEmpty
                      ? 'Pick one or more'
                      : '${state.selected.length} selected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: state.selected.isEmpty
                        ? cs.onSurfaceVariant
                        : cs.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _sortAlpha
                        ? Icons.sort_by_alpha
                        : Icons.signal_cellular_alt,
                    size: 16,
                  ),
                  tooltip: _sortAlpha
                      ? 'Sorted A–Z · tap for by spend'
                      : 'Sorted by spend · tap for A–Z',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _sortAlpha = !_sortAlpha),
                ),
                if (state.selected.isNotEmpty)
                  TextButton(
                    onPressed: () => ref
                        .read(categoryExplorerProvider.notifier)
                        .clearSelection(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: summariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _panelMessage(
                theme,
                e is DatabaseNotConfiguredException
                    ? 'No data source configured yet.'
                    : 'Could not read the database.',
              ),
              data: (summaries) {
                final q = _search.toLowerCase();
                // The SQL orders by spend; re-sort alphabetically by default.
                final visible = (q.isEmpty
                    ? List.of(summaries)
                    : summaries
                          .where(
                            (s) =>
                                prettyCategory(
                                  s.category,
                                ).toLowerCase().contains(q) ||
                                s.category.toLowerCase().contains(q),
                          )
                          .toList());
                if (_sortAlpha) {
                  visible.sort((a, b) => a.category.compareTo(b.category));
                }
                if (visible.isEmpty) {
                  return _panelMessage(theme, 'No categories match');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => _categoryTile(
                    theme,
                    visible[i],
                    state.selected.contains(visible[i].category),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelMessage(ThemeData theme, String msg) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      msg,
      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
    ),
  );

  Widget _categoryTile(ThemeData theme, CategorySummary s, bool selected) {
    final cs = theme.colorScheme;
    final accent = categoryAccent(context, ref, s.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              ref.read(categoryExplorerProvider.notifier).toggle(s.category),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Check indicator, matching the dashboard filter's style.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? cs.primary : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 13, color: cs.onPrimary)
                      : null,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 17,
                  child: FaIcon(
                    categoryIcon(s.category),
                    size: 13,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prettyCategory(s.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      Text(
                        '${s.count} transaction${s.count == 1 ? '' : 's'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  compactMoney(s.total),
                  style: tableNumberStyle(theme, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- results
  Widget _buildResults(ThemeData theme) {
    final cs = theme.colorScheme;
    final state = ref.watch(categoryExplorerProvider);
    if (state.selected.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.16),
                    cs.tertiary.withValues(alpha: 0.10),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.category_rounded, size: 44, color: cs.primary),
            ),
            const SizedBox(height: 18),
            Text(
              'Pick one or more categories',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Every matching transaction across your entire history\n'
              'will appear here — narrow it with a period if you like.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final txAsync = ref.watch(categoryTransactionsProvider);
    return Column(
      children: [
        _buildPeriodBar(theme, state),
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Could not load transactions: $e',
                style: theme.textTheme.bodySmall,
              ),
            ),
            data: (rows) => _buildLoaded(theme, rows),
          ),
        ),
      ],
    );
  }

  /// "All time" by default; an optional custom range narrows the result.
  Widget _buildPeriodBar(ThemeData theme, CategoryExplorerState state) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Icon(Icons.event, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('All time', style: TextStyle(fontSize: 12)),
            avatar: state.hasPeriod
                ? null
                : Icon(Icons.check, size: 14, color: cs.primary),
            showCheckmark: false,
            selected: !state.hasPeriod,
            onSelected: (_) =>
                ref.read(categoryExplorerProvider.notifier).clearPeriod(),
          ),
          const SizedBox(width: 8),
          if (state.hasPeriod)
            InputChip(
              avatar: const Icon(Icons.date_range, size: 14),
              label: Text(
                '${_fmtDate(state.startDate!)} – ${_fmtDate(state.endDate!)}',
                style: const TextStyle(fontSize: 12),
              ),
              selected: true,
              showCheckmark: false,
              onPressed: _pickRange,
              onDeleted: () =>
                  ref.read(categoryExplorerProvider.notifier).clearPeriod(),
              deleteButtonTooltipMessage: 'Back to all time',
            )
          else
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 14),
              label: const Text(
                'Custom period…',
                style: TextStyle(fontSize: 12),
              ),
              onPressed: _pickRange,
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final state = ref.read(categoryExplorerProvider);
    DateTimeRange? initial;
    final s = state.startDate == null
        ? null
        : DateTime.tryParse(state.startDate!);
    final e = state.endDate == null ? null : DateTime.tryParse(state.endDate!);
    if (s != null && e != null && !e.isBefore(s)) {
      initial = DateTimeRange(start: s, end: e);
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
      helpText: 'Select date range',
      saveText: 'Apply',
    );
    if (picked != null) {
      ref
          .read(categoryExplorerProvider.notifier)
          .setPeriod(_fmtIso(picked.start), _fmtIso(picked.end));
    }
  }

  String _fmtIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// '2024-03-08' → '8 Mar 2024'; anything unparseable passes through.
  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('d MMM yyyy').format(d);
  }

  // ----------------------------------------------------------------- loaded
  Widget _buildLoaded(ThemeData theme, List<Expense> rows) {
    final cs = theme.colorScheme;
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 44, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              'No transactions for this selection',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    double total = 0, largest = 0;
    final months = <String>{};
    for (final e in rows) {
      if (e.debit > 0) {
        total += e.debit;
        if (e.debit > largest) largest = e.debit;
        if (e.date.length >= 7) months.add(e.date.substring(0, 7));
      }
    }
    final avgPerMonth = months.isEmpty ? 0.0 : total / months.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: LayoutBuilder(
            builder: (context, c) {
              const gap = 12.0;
              final cols = (c.maxWidth / 210).floor().clamp(2, 4);
              final w = (c.maxWidth - (cols - 1) * gap) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _kpi(
                    theme,
                    w,
                    'Total spent',
                    currency0.format(total),
                    Icons.south_west,
                    cs.error,
                  ),
                  _kpi(
                    theme,
                    w,
                    'Transactions',
                    NumberFormat.decimalPattern().format(rows.length),
                    Icons.receipt_long,
                    cs.primary,
                  ),
                  _kpi(
                    theme,
                    w,
                    'Avg / month',
                    currency0.format(avgPerMonth),
                    Icons.calendar_view_month,
                    cs.tertiary,
                  ),
                  _kpi(
                    theme,
                    w,
                    'Largest',
                    currency0.format(largest),
                    Icons.trending_up,
                    cs.error,
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'transactions',
                    label: Text('Transactions'),
                    icon: Icon(Icons.table_rows, size: 16),
                  ),
                  ButtonSegment(
                    value: 'overview',
                    label: Text('Overview'),
                    icon: Icon(Icons.insights, size: 16),
                  ),
                ],
                selected: {_section},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _section = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          // Overview leads with the per-transaction chart; the per-category
          // bar chart is dropped there (one bar per selected category says
          // less than the list panel already does).
          child: _section == 'overview'
              ? OverviewCharts(
                  transactions: rows,
                  showCategoryBar: false,
                  leading: [
                    TransactionsBarChart(transactions: rows),
                    const SizedBox(height: 24),
                  ],
                )
              : _buildTable(theme, rows),
        ),
      ],
    );
  }

  Widget _kpi(
    ThemeData theme,
    double width,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: brutalBox(theme.colorScheme),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: dashboardNumberStyle(theme.textTheme.titleLarge),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ table
  // A streamlined transactions table: sortable on every column (newest first
  // by default), virtualised, no pagination — selections are typically a few
  // hundred rows.
  List<Expense> _sortRows(List<Expense> list) {
    final sorted = List<Expense>.from(list);
    double amt(Expense e) => e.debit > 0 ? -e.debit : e.credit;
    int cmp(Expense a, Expense b) {
      final r = switch (_sortKey) {
        'description' => a.description.toLowerCase().compareTo(
          b.description.toLowerCase(),
        ),
        'bank' => a.source.toLowerCase().compareTo(b.source.toLowerCase()),
        'category' => a.category.toLowerCase().compareTo(
          b.category.toLowerCase(),
        ),
        'amount' => amt(a).compareTo(amt(b)),
        _ => a.date.compareTo(b.date),
      };
      return _sortAsc ? r : -r;
    }

    sorted.sort(cmp);
    return sorted;
  }

  void _onSort(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortKey = key;
        _sortAsc = true;
      }
    });
  }

  Widget _buildTable(ThemeData theme, List<Expense> rows) {
    final cs = theme.colorScheme;
    final q = _txSearch.trim().toLowerCase();
    final filtered = q.isEmpty
        ? rows
        : rows.where((e) => e.description.toLowerCase().contains(q)).toList();
    final sorted = _sortRows(filtered);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _txSearchCtrl,
            decoration: InputDecoration(
              hintText: 'Search transaction description…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _txSearch.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _txSearchCtrl.clear();
                        setState(() => _txSearch = '');
                      },
                    ),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _txSearch = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: brutalBox(cs),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
                      border: Border(
                        bottom: BorderSide(color: cs.outlineVariant, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _headerCell(theme, '#', 52),
                        _headerCell(theme, 'DATE', 110, sortKey: 'date'),
                        _headerCell(
                          theme,
                          'DESCRIPTION',
                          null,
                          sortKey: 'description',
                        ),
                        _headerCell(theme, 'BANK', 100, sortKey: 'bank'),
                        _headerCell(
                          theme,
                          'AMOUNT',
                          110,
                          right: true,
                          sortKey: 'amount',
                        ),
                        const SizedBox(width: 18),
                        _headerCell(
                          theme,
                          'CATEGORY',
                          150,
                          sortKey: 'category',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sorted.isEmpty
                        ? _emptyTableState(theme)
                        : SelectionArea(
                            child: ListView.builder(
                              itemCount: sorted.length,
                              itemBuilder: (context, i) =>
                                  _tableRow(theme, sorted[i], i),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTableState(ThemeData theme) {
    final cs = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 36, color: cs.outline),
          const SizedBox(height: 10),
          Text(
            'No transactions match your search',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
    ThemeData theme,
    String label,
    double? width, {
    bool right = false,
    String? sortKey,
  }) {
    final cs = theme.colorScheme;
    final active = sortKey != null && sortKey == _sortKey;
    final content = Row(
      mainAxisAlignment: right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
              color: active ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
        if (sortKey != null) ...[
          const SizedBox(width: 2),
          Icon(
            active
                ? (_sortAsc ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 13,
            color: active
                ? cs.primary
                : cs.onSurfaceVariant.withValues(alpha: 0.55),
          ),
        ],
      ],
    );
    final cell = sortKey == null
        ? content
        : InkWell(onTap: () => _onSort(sortKey), child: content);
    return width == null
        ? Expanded(child: cell)
        : SizedBox(width: width, child: cell);
  }

  Widget _tableRow(ThemeData theme, Expense tx, int i) {
    final cs = theme.colorScheme;
    final amount = tx.debit > 0 ? -tx.debit : tx.credit;
    final isDebit = tx.debit > 0;
    Widget cell(
      String v,
      double? width, {
      bool right = false,
      Color? color,
      FontWeight? weight,
      bool numeric = false,
    }) {
      final text = Text(
        v,
        textAlign: right ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: numeric
            ? tableNumberStyle(
                theme,
                color: color,
                fontWeight: weight ?? FontWeight.w800,
              )
            : TextStyle(
                fontSize: 12.5,
                fontWeight: weight ?? FontWeight.w500,
                color: color ?? cs.onSurface,
              ),
      );
      return width == null
          ? Expanded(child: text)
          : SizedBox(width: width, child: text);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: i.isOdd ? cs.surfaceContainerLow : null,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          cell('${i + 1}', 52, color: cs.onSurfaceVariant),
          cell(_fmtDate(tx.date), 110),
          cell(tx.description, null),
          cell(tx.source, 100),
          cell(
            currency2.format(amount),
            110,
            right: true,
            weight: FontWeight.w700,
            color: isDebit ? cs.error : Colors.green.shade700,
            numeric: true,
          ),
          const SizedBox(width: 18),
          SizedBox(width: 150, child: CategoryPill(category: tx.category)),
        ],
      ),
    );
  }
}
