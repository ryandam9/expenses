import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_filter.dart';
import '../services/database_service.dart';
import '../providers/filter_provider.dart';

class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  final _db = DatabaseService();

  List<String> _categories = [];
  List<String> _years = [];

  String _mode = 'monthly'; // 'monthly' | 'custom'
  String? _selYear;
  int _selMonth = 0; // 0 = whole year
  bool _catExpanded = false;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final years = await _db.getYears();
      final cats = await _db.getCategoriesForPeriod(filter: ref.read(filterProvider));
      if (mounted) {
        setState(() {
          _categories = cats;
          _years = years;
          _selYear = years.isNotEmpty ? years.first : null;
        });
      }
    } catch (_) {}
  }

  /// Reloads the category options for the given period and drops any selected
  /// categories that no longer exist within it.
  Future<void> _loadPeriodCategories(AppFilter f) async {
    try {
      final cats = await _db.getCategoriesForPeriod(filter: f);
      if (!mounted) return;
      setState(() => _categories = cats);
      final selected = f.categories;
      if (selected.isNotEmpty) {
        final pruned = selected.where(cats.contains).toList();
        if (pruned.length != selected.length) {
          ref.read(filterProvider.notifier).setCategories(pruned);
        }
      }
    } catch (_) {}
  }

  String _lastDay(int year, int month) =>
      DateTime(year, month + 1, 0).day.toString().padLeft(2, '0');

  void _applyMonthly() {
    final year = _selYear;
    if (year == null) return;
    final notifier = ref.read(filterProvider.notifier);
    if (_selMonth == 0) {
      notifier.setRange('$year-01-01', '$year-12-31');
    } else {
      final mm = _selMonth.toString().padLeft(2, '0');
      notifier.setRange(
          '$year-$mm-01', '$year-$mm-${_lastDay(int.parse(year), _selMonth)}');
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final filter = ref.read(filterProvider);
    DateTimeRange? initial;
    final s = _parse(filter.startDate);
    final e = _parse(filter.endDate);
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
      ref.read(filterProvider.notifier).setRange(_fmt(picked.start), _fmt(picked.end));
    }
  }

  DateTime? _parse(String? d) {
    if (d == null || d.isEmpty) return null;
    return DateTime.tryParse(d);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _clear() {
    setState(() {
      _catExpanded = false;
      _selMonth = 0;
    });
    ref.read(filterProvider.notifier).clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider);
    final hasFilter = filter.hasPeriod || filter.hasCategories;

    // Keep the category options in sync with the selected period.
    ref.listen(filterProvider, (prev, next) {
      if (prev?.startDate != next.startDate || prev?.endDate != next.endDate) {
        _loadPeriodCategories(next);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'monthly',
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_view_month, size: 16),
                  ),
                  ButtonSegment(
                    value: 'custom',
                    label: Text('Custom'),
                    icon: Icon(Icons.date_range, size: 16),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _mode = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Spacer(),
              _buildCategoryChip(theme, filter),
              if (hasFilter) ...[
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: _clear,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  tooltip: 'Clear filters',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (_mode == 'monthly')
            _buildMonthlyControls(theme)
          else
            _buildCustomControls(theme, filter),
          if (_catExpanded) _buildCategoryPanel(theme, filter),
        ],
      ),
    );
  }

  Widget _buildMonthlyControls(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownMenu<String>(
            initialSelection: _selYear,
            enableSearch: false,
            expandedInsets: EdgeInsets.zero,
            label: const Text('Year'),
            leadingIcon: const Icon(Icons.event, size: 18),
            dropdownMenuEntries:
                _years.map((y) => DropdownMenuEntry(value: y, label: y)).toList(),
            onSelected: (v) {
              if (v != null) {
                setState(() => _selYear = v);
                _applyMonthly();
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: DropdownMenu<int>(
            initialSelection: _selMonth,
            enableSearch: false,
            expandedInsets: EdgeInsets.zero,
            label: const Text('Month'),
            leadingIcon: const Icon(Icons.calendar_month, size: 18),
            dropdownMenuEntries: [
              const DropdownMenuEntry(value: 0, label: 'Whole year'),
              for (var m = 1; m <= 12; m++)
                DropdownMenuEntry(value: m, label: _monthNames[m - 1]),
            ],
            onSelected: (v) {
              if (v != null) {
                setState(() => _selMonth = v);
                _applyMonthly();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomControls(ThemeData theme, AppFilter filter) {
    final hasRange = filter.hasPeriod;
    String label = 'Select date range';
    if (hasRange) {
      final s = filter.startDate ?? '…';
      final e = filter.endDate ?? '…';
      label = '$s  →  $e';
    }
    return InkWell(
      onTap: () => _pickRange(context),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
          color: hasRange ? theme.colorScheme.primaryContainer : null,
        ),
        child: Row(
          children: [
            Icon(Icons.date_range,
                size: 18,
                color: hasRange
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: hasRange
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.edit_calendar,
                size: 18,
                color: hasRange
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ThemeData theme, AppFilter filter) {
    final notifier = ref.read(filterProvider.notifier);
    final label = notifier.categoriesLabel;
    return GestureDetector(
      onTap: () => setState(() => _catExpanded = !_catExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          color: filter.hasCategories
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16,
              color: filter.hasCategories
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: filter.hasCategories
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _catExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: filter.hasCategories
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPanel(ThemeData theme, AppFilter filter) {
    final allSelected = filter.categories.isEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Categories in period', style: theme.textTheme.labelLarge),
                const Spacer(),
                Text(
                  allSelected ? 'All' : '${filter.categories.length} selected',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            value: allSelected,
            title: const Text('All categories',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            onChanged: (_) => ref.read(filterProvider.notifier).setCategories([]),
          ),
          const Divider(height: 1),
          if (_categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No categories in this period',
                  style: TextStyle(fontSize: 12)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = filter.categories.contains(c);
                  return CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    value: selected,
                    title: Text(
                      c.replaceAll('-', ' ').toLowerCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onChanged: (_) =>
                        ref.read(filterProvider.notifier).toggleCategory(c),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
