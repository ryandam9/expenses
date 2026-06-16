import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/query_builder.dart';
import '../providers/dashboard_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/prefs_provider.dart';
import '../theme/app_themes.dart';
import '../theme/app_ui.dart';
import '../theme/brutalism.dart';
import '../theme/typography.dart';
import '../models/expense.dart';
import '../utils/format.dart';
import '../widgets/category_pill.dart';
import '../widgets/filter_bar.dart';
import '../widgets/db_path_dialog.dart';
import '../widgets/overview_charts.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _vScroll = ScrollController();
  final _hScroll = ScrollController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  String _section = 'transactions';
  String _query = '';

  // Label of the KPI tile currently under the pointer ('' = none); drives the
  // tile's hover lift.
  String _hoveredKpi = '';

  int _page = 0;
  int _pageSize = 50;
  static const _pageSizeOptions = [25, 50, 100, 200];

  String _sortKey = 'date';
  bool _sortAsc = false;

  // Current per-column widths, seeded from the defaults in [_columns] (or the
  // last saved widths). Drag the grips in the header to resize; double-tap a
  // grip to restore the default.
  late List<double> _colWidths;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _colWidths = [for (final c in _columns) c.$2];
    final saved = ref.read(sharedPreferencesProvider).getString('colWidths');
    if (saved != null) {
      final parts = saved
          .split(',')
          .map(double.tryParse)
          .whereType<double>()
          .toList();
      if (parts.length == _columns.length) _colWidths = parts;
    }
  }

  void _saveColWidths() {
    ref
        .read(sharedPreferencesProvider)
        .setString('colWidths', _colWidths.join(','));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _vScroll.dispose();
    _hScroll.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Rows matching the free-text search, drawn from [all]. KPIs, charts and
  /// the table are all computed from this, so everything on screen agrees.
  List<Expense> _filtered(List<Expense> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where(
          (e) =>
              e.description.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q) ||
              e.source.toLowerCase().contains(q),
        )
        .toList();
  }

  void _focusSearch() {
    if (_section != 'transactions') {
      setState(() => _section = 'transactions');
    }
    // After a section switch the field mounts on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    // Route through the shared provider; its listener resets _query/_page and
    // keeps the top-bar field in sync.
    ref.read(globalSearchProvider.notifier).set('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(dashboardDataProvider);

    // The global top-bar search drives this screen's query too. Mirror any
    // external change into the local field/state without disturbing the
    // caret while the user types here.
    ref.listen<String>(globalSearchProvider, (prev, next) {
      if (!mounted) return;
      if (_query != next) {
        setState(() {
          _query = next;
          _page = 0;
        });
      }
      if (_searchCtrl.text != next) {
        _searchCtrl.text = next;
        _searchCtrl.selection = TextSelection.collapsed(offset: next.length);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FilterPanel(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(theme, async),
                Expanded(child: _buildBody(theme, async)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Page header: title plus the active period on the left, the section
  /// switcher and export menu on the right.
  Widget _buildHeader(ThemeData theme, AsyncValue<DashboardData> async) {
    final filter = ref.watch(filterProvider);
    final period = filter.hasPeriod
        ? '${_fmtDate(filter.startDate ?? '')}  –  ${_fmtDate(filter.endDate ?? '')}'
        : 'All time';

    return LayoutBuilder(
      builder: (context, c) {
        // On narrow windows the section switcher collapses to icon-only
        // segments (with tooltips) so the header never overflows.
        final compact = c.maxWidth < 640;
        return AppPageHeader(
          icon: Icons.receipt_long_rounded,
          title: 'Transactions',
          subtitle: period,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'transactions',
                    label: compact ? null : const Text('Transactions'),
                    tooltip: compact ? 'Transactions' : null,
                    icon: const Icon(Icons.table_rows, size: 16),
                  ),
                  ButtonSegment(
                    value: 'overview',
                    label: compact ? null : const Text('Overview'),
                    tooltip: compact ? 'Overview' : null,
                    icon: const Icon(Icons.insights, size: 16),
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
              const SizedBox(width: 10),
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.table_rows, size: 18),
                    onPressed: async.hasValue
                        ? () => _exportCsv(
                            async.requireValue.transactions,
                            overview: false,
                          )
                        : null,
                    child: const Text('Export transactions (CSV)'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(
                      Icons.donut_small_outlined,
                      size: 18,
                    ),
                    onPressed: async.hasValue
                        ? () => _exportCsv(
                            async.requireValue.transactions,
                            overview: true,
                          )
                        : null,
                    child: const Text('Export category summary (CSV)'),
                  ),
                ],
                builder: (context, controller, _) => IconButton.filledTonal(
                  icon: const Icon(Icons.download_rounded, size: 20),
                  tooltip: 'Export',
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme, AsyncValue<DashboardData> async) {
    // Riverpod keeps the previous value while a reload is in flight, so prefer
    // showing (slightly stale) data behind a thin progress bar over a spinner.
    final data = async.hasValue ? async.requireValue : null;
    if (data != null) return _buildLoaded(theme, data, async.isLoading);
    if (async.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading your transactions…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    final err = async.error;
    if (err is DatabaseNotConfiguredException) return _buildSetup(theme);
    return _buildError(theme, err.toString());
  }

  Widget _buildLoaded(ThemeData theme, DashboardData data, bool reloading) {
    final filtered = _filtered(data.transactions);
    final content = Column(
      children: [
        SizedBox(
          height: 3,
          child: reloading ? const LinearProgressIndicator(minHeight: 3) : null,
        ),
        _buildKpiHeader(theme, filtered, data),
        if (_query.isNotEmpty)
          _buildSearchChip(theme, filtered.length, data.transactions.length),
        Divider(
          height: 1,
          thickness: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        Expanded(
          child: _section == 'overview'
              ? OverviewCharts(transactions: filtered)
              : _buildTransactionsView(theme, filtered),
        ),
      ],
    );
    // Ambient design: the surface is lit by two soft, palette-coloured glows
    // bleeding in from opposite corners. Alpha is kept very low so the base
    // stays bright and text contrast is untouched.
    final body = DecoratedBox(
      decoration: BoxDecoration(gradient: _ambientGlow(theme)),
      child: content,
    );
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length / _pageSize).ceil();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _focusSearch,
        const SingleActivator(LogicalKeyboardKey.pageDown): () {
          if (_section == 'transactions' && _page < pageCount - 1) {
            setState(() => _page++);
          }
        },
        const SingleActivator(LogicalKeyboardKey.pageUp): () {
          if (_section == 'transactions' && _page > 0) {
            setState(() => _page--);
          }
        },
      },
      child: Focus(autofocus: true, child: body),
    );
  }

  Gradient _ambientGlow(ThemeData theme) {
    final palette = appThemes[ref.watch(themeIndexProvider)].palette;
    final a = (palette.isNotEmpty ? palette.first : theme.colorScheme.primary)
        .withValues(alpha: 0.15);
    final b = (palette.length > 2 ? palette[2] : theme.colorScheme.tertiary)
        .withValues(alpha: 0.10);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [a, Colors.transparent, b],
      stops: const [0.0, 0.55, 1.0],
    );
  }

  // ------------------------------------------------------------------ export
  // Writes the chosen view to a CSV picked via the platform's save dialog.
  Future<void> _exportCsv(List<Expense> all, {required bool overview}) async {
    try {
      final filtered = _filtered(all);
      final content = overview
          ? categorySummaryToCsv(debitTotalsBy(filtered, (e) => e.category))
          : transactionsToCsv(_sortList(filtered));
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final base = overview ? 'category_summary' : 'transactions';
      final location = await getSaveLocation(
        suggestedName: 'expenses_${base}_$ts.csv',
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (location == null) return; // cancelled
      final file = File(location.path);
      await file.writeAsString(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to ${file.path}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Copy path',
            onPressed: () => Clipboard.setData(ClipboardData(text: file.path)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  // ---------------------------------------------------------------- KPI header
  Widget _buildKpiHeader(
    ThemeData theme,
    List<Expense> rows,
    DashboardData data,
  ) {
    double totalDebits = 0, largest = 0;
    for (final e in rows) {
      if (e.debit > 0) {
        totalDebits += e.debit;
        if (e.debit > largest) largest = e.debit;
      }
    }

    // "vs previous period" deltas only make sense against unsearched totals.
    final debitDelta = _query.isEmpty
        ? _delta(theme, totalDebits, data.prevDebits, upIsGood: false)
        : null;

    final tiles = <Widget Function(double)>[
      (w) => _kpi(
        theme,
        w,
        'Expenses',
        currency0.format(totalDebits),
        Icons.south_west,
        theme.colorScheme.error,
        delta: debitDelta,
      ),
      (w) => _kpi(
        theme,
        w,
        'Transactions',
        NumberFormat.decimalPattern().format(rows.length),
        Icons.receipt_long,
        theme.colorScheme.primary,
      ),
      (w) => _kpi(
        theme,
        w,
        'Largest',
        currency0.format(largest),
        Icons.trending_up,
        theme.colorScheme.error,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 12.0;
          final cols = (c.maxWidth / 210).floor().clamp(2, tiles.length);
          final w = (c.maxWidth - (cols - 1) * gap) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final t in tiles) t(w)],
          );
        },
      ),
    );
  }

  /// Compact "▲ 12% vs prev" readout. [upIsGood] flips the colour semantics:
  /// rising income is good (green), rising expenses are not (red).
  Widget? _delta(
    ThemeData theme,
    double current,
    double? previous, {
    required bool upIsGood,
  }) {
    if (previous == null || previous <= 0) return null;
    final pct = (current - previous) / previous * 100;
    final up = pct >= 0;
    final good = up == upIsGood;
    final color = good ? Colors.green.shade700 : theme.colorScheme.error;
    // `.min` is a Dart 3.10 dot shorthand for MainAxisSize.min.
    return Row(
      mainAxisSize: .min,
      children: [
        Icon(
          up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          size: 16,
          color: color,
        ),
        Text(
          '${pct.abs().toStringAsFixed(0)}% vs prev',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
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
    Color color, {
    Widget? delta,
  }) {
    final hovered = _hoveredKpi == label;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredKpi = label),
      onExit: (_) => setState(() {
        if (_hoveredKpi == label) _hoveredKpi = '';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        padding: const EdgeInsets.all(13),
        // Hovering lifts the tile: it rises a few pixels and its accent
        // shadow deepens, giving the header a tactile, layered feel.
        transform: Matrix4.translationValues(0, hovered ? -2 : 0, 0),
        decoration: brutalBox(
          theme.colorScheme,
          dx: hovered ? 5 : 3,
          dy: hovered ? 5 : 3,
        ),
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
                crossAxisAlignment: .start,
                mainAxisSize: .min,
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
                  ?delta,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Makes the search's effect on the totals explicit: KPIs and charts cover
  /// only the matching rows while this chip is visible.
  Widget _buildSearchChip(ThemeData theme, int shown, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          InputChip(
            avatar: const Icon(Icons.search, size: 16),
            label: Text(
              'Search “$_query” — totals cover $shown of $total transactions',
              style: const TextStyle(fontSize: 12),
            ),
            onDeleted: _clearSearch,
            deleteButtonTooltipMessage: 'Clear search',
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- transactions
  Widget _buildTransactionsView(ThemeData theme, List<Expense> filtered) {
    final all = _sortList(filtered);
    final total = all.length;
    final pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_page >= pageCount) _page = pageCount - 1;
    final startIndex = _page * _pageSize;
    final pageItems = all.skip(startIndex).take(_pageSize).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            decoration: InputDecoration(
              hintText: 'Search description, category or bank…  (Ctrl+F)',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearSearch,
                    ),
              isDense: true,
            ),
            onChanged: (v) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                if (!mounted) return;
                // The provider's listener updates _query and resets the page.
                ref.read(globalSearchProvider.notifier).set(v);
              });
            },
          ),
          const SizedBox(height: 12),
          // The table lives in its own elevated card so the data region reads
          // as one cohesive surface on the tinted canvas.
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: brutalBox(theme.colorScheme),
              child: Column(
                children: [
                  Expanded(child: _buildTable(theme, pageItems, startIndex)),
                  _buildPaginationBar(
                    theme,
                    total,
                    startIndex,
                    pageItems.length,
                    pageCount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (label, width, alignment, sortKey?) — null sortKey = not sortable.
  static const _columns = <(String, double, TextAlign, String?)>[
    ('#', 56, TextAlign.left, null),
    ('DATE', 108, TextAlign.left, 'date'),
    ('DESCRIPTION', 340, TextAlign.left, 'description'),
    ('BANK', 100, TextAlign.left, 'bank'),
    ('AMOUNT', 130, TextAlign.right, 'amount'),
    ('CATEGORY', 160, TextAlign.left, 'category'),
  ];

  // Horizontal gap rendered after each cell so columns don't touch.
  static const _cellGap = 18.0;

  static const _minColWidth = 48.0;
  static const _maxColWidth = 640.0;

  double get _tableWidth =>
      _colWidths.fold(0.0, (s, w) => s + w + _cellGap) + 32;

  void _resizeColumn(int i, double dx) {
    setState(() {
      _colWidths[i] = (_colWidths[i] + dx).clamp(_minColWidth, _maxColWidth);
    });
    _saveColWidths();
  }

  List<Expense> _sortList(List<Expense> list) {
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
      _page = 0;
    });
  }

  Widget _buildTable(ThemeData theme, List<Expense> list, int startIndex) {
    if (list.isEmpty) {
      return _emptyCenter(theme, Icons.search_off, 'No transactions match');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _tableWidth < constraints.maxWidth
            ? constraints.maxWidth
            : _tableWidth;
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
                      child: SelectionArea(
                        child: ListView.builder(
                          controller: _vScroll,
                          itemCount: list.length,
                          itemBuilder: (context, i) =>
                              _tableRow(theme, list[i], startIndex + i, i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeader(ThemeData theme) {
    final cs = theme.colorScheme;
    // A quiet, toned header (modern data-table style); the active sort column
    // is picked out in the primary colour instead of a loud band.
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _columns.length; i++) ...[
            _headerCell(theme, i),
            _resizeHandle(i, cs.outline.withValues(alpha: 0.45)),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(ThemeData theme, int i) {
    final cs = theme.colorScheme;
    final c = _columns[i];
    final key = c.$4;
    final active = key != null && key == _sortKey;
    final isRight = c.$3 == TextAlign.right;
    final label = Text(
      c.$1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 0.6,
        color: active ? cs.primary : cs.onSurfaceVariant,
      ),
    );
    final content = Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: isRight
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(child: label),
        if (key != null) ...[
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
    return SizedBox(
      width: _colWidths[i],
      child: key == null
          ? content
          : InkWell(onTap: () => _onSort(key), child: content),
    );
  }

  // A draggable grip occupying the inter-column gap. Drag to resize the column
  // to its left; double-tap to reset it to the default width.
  Widget _resizeHandle(int i, Color gripColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => _resizeColumn(i, d.delta.dx),
        onDoubleTap: () {
          setState(() => _colWidths[i] = _columns[i].$2);
          _saveColWidths();
        },
        child: Semantics(
          label: 'Resize ${_columns[i].$1} column',
          child: Tooltip(
            message: 'Drag to resize · double-tap to reset',
            child: SizedBox(
              width: _cellGap,
              height: double.infinity,
              child: Center(
                child: Container(width: 1.5, height: 16, color: gripColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// '2024-03-08' → '8 Mar 2024'; anything unparseable passes through.
  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('d MMM yyyy').format(d);
  }

  Widget _tableRow(
    ThemeData theme,
    Expense tx,
    int displayIndex,
    int rowInPage,
  ) {
    final amount = tx.debit > 0 ? -tx.debit : tx.credit;
    final isDebit = tx.debit > 0;
    final values = <String>[
      '${displayIndex + 1}',
      _fmtDate(tx.date),
      tx.description,
      tx.source,
      currency2.format(amount),
      '', // category renders as a coloured pill, not text
    ];
    return InkWell(
      onTap: () => _showTxDetail(theme, tx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: rowInPage.isOdd ? theme.colorScheme.surfaceContainerLow : null,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          // Rows size to their content so a long description can wrap onto
          // several lines; top-align the other cells against the first line.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_columns.length, (c) {
            final isAmount = c == 4;
            final isDescription = c == 2;
            final isCategory = c == 5;
            return Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: SizedBox(
                width: _colWidths[c],
                child: isCategory
                    ? CategoryPill(category: tx.category)
                    : Text(
                        values[c],
                        textAlign: _columns[c].$3,
                        softWrap: isDescription,
                        overflow: isDescription
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        maxLines: isDescription ? null : 1,
                        style: isAmount
                            ? tableNumberStyle(
                                theme,
                                color: isDebit
                                    ? theme.colorScheme.error
                                    : Colors.green.shade700,
                              )
                            : TextStyle(
                                fontSize: 12.5,
                                height: isDescription ? 1.35 : null,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showTxDetail(ThemeData theme, Expense tx) {
    final amount = tx.debit > 0 ? -tx.debit : tx.credit;
    final isDebit = tx.debit > 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isDebit ? Icons.south_west : Icons.north_east,
          color: isDebit ? theme.colorScheme.error : Colors.green.shade600,
        ),
        title: Text(
          currency2.format(amount),
          style: dashboardNumberStyle(
            theme.textTheme.headlineSmall,
            color: isDebit ? theme.colorScheme.error : Colors.green.shade700,
          ),
        ),
        content: SelectionArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(theme, 'Description', tx.description),
              _detailRow(theme, 'Date', _fmtDate(tx.date)),
              _detailRow(theme, 'Category', prettyCategory(tx.category)),
              _detailRow(theme, 'Bank', tx.source),
              if (tx.debit > 0)
                _detailRow(theme, 'Debit', currency2.format(tx.debit)),
              if (tx.credit > 0)
                _detailRow(theme, 'Credit', currency2.format(tx.credit)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      '${tx.date} | ${tx.description} | '
                      '${tx.category} | ${tx.source} | ${currency2.format(amount)}',
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(
    ThemeData theme,
    int total,
    int startIndex,
    int shown,
    int pageCount,
  ) {
    final from = total == 0 ? 0 : startIndex + 1;
    final to = startIndex + shown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
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
                .map(
                  (n) => DropdownMenuItem(
                    value: n,
                    child: Text(
                      '$n',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => v == null
                ? null
                : setState(() {
                    _pageSize = v;
                    _page = 0;
                  }),
          ),
          const Spacer(),
          Text(
            '$from–$to of $total',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          IconButton.outlined(
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left, size: 20),
            tooltip: 'Previous (PgUp)',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_page + 1} / $pageCount',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          IconButton.outlined(
            onPressed: _page < pageCount - 1
                ? () => setState(() => _page++)
                : null,
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Next (PgDn)',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- helpers
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

  /// First-run state: no database has been configured yet.
  Widget _buildSetup(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                      theme.colorScheme.primary.withValues(alpha: 0.16),
                      theme.colorScheme.tertiary.withValues(alpha: 0.10),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 44,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Choose your expenses database',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point the app at the SQLite file that contains your '
                'expenses table. You can change it later in Settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showDbPathDialog(context, ref),
                icon: const Icon(Icons.storage_rounded),
                label: const Text('Choose database…'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                "Couldn't load your data",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current source: ${DatabaseService().currentPath ?? 'not configured'}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(dashboardDataProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  FilledButton.icon(
                    onPressed: () => showDbPathDialog(context, ref),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Set data source'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
