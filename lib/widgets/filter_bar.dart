import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_filter.dart';
import '../services/database_service.dart';
import '../providers/filter_provider.dart';

/// Persistent vertical filter sidebar: period selection (monthly or custom)
/// plus a multi-select category checklist scoped to the selected period.
class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({super.key});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  final _db = DatabaseService();

  List<String> _categories = [];
  List<String> _years = [];

  String _mode = 'monthly'; // 'monthly' | 'custom'
  String? _selYear;
  int _selMonth = 0; // 0 = whole year

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
      final cats =
          await _db.getCategoriesForPeriod(filter: ref.read(filterProvider));
      if (mounted) {
        setState(() {
          _categories = cats;
          _years = years;
          _selYear = years.isNotEmpty ? years.first : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPeriodCategories(AppFilter f) async {
    try {
      final cats = await _db.getCategoriesForPeriod(filter: f);
      if (!mounted) return;
      setState(() => _categories = cats);
      // Drop any explicit selections that no longer exist in this period.
      if (!f.allCategories && f.categories.isNotEmpty) {
        final pruned = f.categories.where(cats.contains).toList();
        if (pruned.length != f.categories.length) {
          ref.read(filterProvider.notifier).setCategories(pruned, cats);
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
      ref
          .read(filterProvider.notifier)
          .setRange(_fmt(picked.start), _fmt(picked.end));
    }
  }

  DateTime? _parse(String? d) =>
      (d == null || d.isEmpty) ? null : DateTime.tryParse(d);

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filter = ref.watch(filterProvider);

    ref.listen(filterProvider, (prev, next) {
      if (prev?.startDate != next.startDate || prev?.endDate != next.endDate) {
        _loadPeriodCategories(next);
      }
    });

    return Container(
      width: 288,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.tune, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text('Filters', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (filter.hasAnyFilter)
                  TextButton(
                    onPressed: () {
                      setState(() => _selMonth = 0);
                      ref.read(filterProvider.notifier).clearAll();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'monthly',
                    label: Text('Monthly'),
                    icon: Icon(Icons.calendar_view_month, size: 16)),
                ButtonSegment(
                    value: 'custom',
                    label: Text('Custom'),
                    icon: Icon(Icons.date_range, size: 16)),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _mode = s.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _mode == 'monthly'
                ? _buildMonthly(theme)
                : _buildCustom(theme, filter),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.category, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Categories', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  filter.allCategories
                      ? 'All'
                      : (filter.categories.isEmpty
                          ? 'None'
                          : '${filter.categories.length}'),
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildCategoryList(theme, filter)),
        ],
      ),
    );
  }

  Widget _buildMonthly(ThemeData theme) {
    return Column(
      children: [
        DropdownMenu<String>(
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
        const SizedBox(height: 10),
        DropdownMenu<int>(
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
      ],
    );
  }

  Widget _buildCustom(ThemeData theme, AppFilter filter) {
    final cs = theme.colorScheme;
    final hasRange = filter.hasPeriod;
    final label = hasRange
        ? '${filter.startDate ?? '…'}  →  ${filter.endDate ?? '…'}'
        : 'Select date range';
    return InkWell(
      onTap: () => _pickRange(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: hasRange ? cs.primaryContainer : null,
        ),
        child: Row(
          children: [
            Icon(Icons.date_range,
                size: 18,
                color: hasRange ? cs.onPrimaryContainer : cs.onSurface),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color:
                          hasRange ? cs.onPrimaryContainer : cs.onSurface),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(ThemeData theme, AppFilter filter) {
    final cs = theme.colorScheme;
    final notifier = ref.read(filterProvider.notifier);
    final allSelected = filter.allCategories;
    final noneSelected = !filter.allCategories && filter.categories.isEmpty;
    // null => indeterminate (a partial selection).
    final bool? masterValue = allSelected ? true : (noneSelected ? false : null);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _categoryTile(
          theme,
          label: 'All categories',
          value: masterValue,
          tristate: true,
          bold: true,
          onChanged: () {
            if (allSelected) {
              notifier.selectNoCategories();
            } else {
              notifier.selectAllCategories();
            }
          },
        ),
        const Divider(height: 1, indent: 12, endIndent: 12),
        if (_categories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No categories in this period',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          )
        else
          ..._categories.map((c) => _categoryTile(
                theme,
                label: c.replaceAll('-', ' ').toLowerCase(),
                value: filter.allCategories || filter.categories.contains(c),
                onChanged: () => notifier.toggleCategory(c, _categories),
              )),
      ],
    );
  }

  Widget _categoryTile(
    ThemeData theme, {
    required String label,
    required bool? value,
    required VoidCallback onChanged,
    bool tristate = false,
    bool bold = false,
  }) {
    final cs = theme.colorScheme;
    final selected = value == true;
    final indeterminate = value == null;
    final marked = selected || indeterminate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onChanged,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Custom check indicator: a rounded square that fills with the
                // accent colour and reveals a tick (or a dash when partial).
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: marked ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: marked ? cs.primary : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: indeterminate
                      ? Icon(Icons.remove, size: 14, color: cs.onPrimary)
                      : (selected
                          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                          : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          (selected || bold) ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
