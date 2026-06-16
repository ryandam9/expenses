import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_filter.dart';
import '../services/database_service.dart';
import '../providers/filter_provider.dart';
import '../providers/prefs_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../theme/brutalism.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Maps an already-applied date range back onto the period controls:
/// `YYYY-01-01..YYYY-12-31` → that year / whole year, a calendar month's exact
/// span → that year and month, anything else → custom mode. Returns null when
/// no period is applied (first launch), in which case the default selection is
/// applied instead.
(String, String?, int)? _restoreFromFilter(AppFilter f, List<String> years) {
  final s = f.startDate;
  final e = f.endDate;
  if (s == null || e == null) return null;
  final year = s.length >= 4 ? s.substring(0, 4) : null;
  if (year != null && years.contains(year)) {
    if (s == '$year-01-01' && e == '$year-12-31') {
      return ('monthly', year, 0);
    }
    for (var m = 1; m <= 12; m++) {
      final mm = m.toString().padLeft(2, '0');
      if (s == '$year-$mm-01' &&
          e == '$year-$mm-${_lastDay(int.parse(year), m)}') {
        return ('monthly', year, m);
      }
    }
  }
  return ('custom', null, 0);
}

String _lastDay(int year, int month) =>
    DateTime(year, month + 1, 0).day.toString().padLeft(2, '0');

// ===========================================================================
// Period bar — a horizontal date-range control across the top of the screen.
// ===========================================================================

/// Horizontal period selector: a Monthly/Custom toggle plus either year/month
/// dropdowns or a custom date-range picker. Drives [filterProvider]'s period;
/// the [FilterPanel] sidebar reloads its category list whenever the period
/// changes.
class PeriodBar extends ConsumerStatefulWidget {
  const PeriodBar({super.key});

  @override
  ConsumerState<PeriodBar> createState() => _PeriodBarState();
}

class _PeriodBarState extends ConsumerState<PeriodBar> {
  final _db = DatabaseService();

  List<String> _years = [];
  // Months (1-12) that actually have data in the selected year, so the
  // dropdown doesn't offer empty months.
  List<int> _months = [];
  String? _error;

  String _mode = 'monthly'; // 'monthly' | 'custom'
  String? _selYear;
  int _selMonth = 0; // 0 = whole year

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final years = await _db.getYears();
      // If a period is already applied (the bar was remounted, e.g. after
      // visiting another screen), restore the controls from it instead of
      // resetting the user's selection.
      final existing = ref.read(filterProvider);
      final restored = _restoreFromFilter(existing, years);
      if (restored != null) {
        final (mode, year, month) = restored;
        final months = year == null ? <int>[] : await _monthsForYear(year);
        if (!mounted) return;
        setState(() {
          _error = null;
          _years = years;
          _months = months;
          _mode = mode;
          _selYear = year;
          _selMonth = month;
        });
        return;
      }
      final first = years.isNotEmpty ? years.first : null;
      final months = first == null ? <int>[] : await _monthsForYear(first);
      if (!mounted) return;
      setState(() {
        _error = null;
        _years = years;
        _months = months;
        _selYear = first;
        _selMonth = 0;
      });
      // Apply the default selection so the dropdowns and the data agree.
      _applyMonthly();
    } catch (e) {
      debugPrint('PeriodBar: failed to load periods: $e');
      if (!mounted) return;
      setState(
        () => _error = e is DatabaseNotConfiguredException
            ? 'No data source configured yet.'
            : 'Could not read the database.',
      );
    }
  }

  Future<List<int>> _monthsForYear(String year) async {
    final mos = await _db.getMonthsForYear(year);
    return mos.map(int.parse).where((m) => m >= 1 && m <= 12).toList();
  }

  void _applyMonthly() {
    final year = _selYear;
    if (year == null) return;
    final notifier = ref.read(filterProvider.notifier);
    if (_selMonth == 0) {
      notifier.setRange('$year-01-01', '$year-12-31');
    } else {
      final mm = _selMonth.toString().padLeft(2, '0');
      notifier.setRange(
        '$year-$mm-01',
        '$year-$mm-${_lastDay(int.parse(year), _selMonth)}',
      );
    }
  }

  Future<void> _selectYear(String year) async {
    List<int> months = _months;
    try {
      months = await _monthsForYear(year);
    } catch (e) {
      debugPrint('PeriodBar: failed to load months for $year: $e');
    }
    if (!mounted) return;
    setState(() {
      _selYear = year;
      _months = months;
      // Keep the month only if it exists in the new year.
      if (_selMonth != 0 && !months.contains(_selMonth)) _selMonth = 0;
    });
    _applyMonthly();
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

    // Refresh the year options when the data source changes.
    ref.listen(dataReloadProvider, (_, _) => _loadOptions());

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: brutalLine(cs), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'DATE RANGE',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                      const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (_mode == 'monthly') ...[
                  SizedBox(
                    width: 132,
                    child: DropdownMenu<String>(
                      // DropdownMenu only reads initialSelection once, so re-key
                      // it when the selection changes programmatically.
                      key: ValueKey('year-$_selYear'),
                      initialSelection: _selYear,
                      enableSearch: false,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Year'),
                      leadingIcon: const Icon(Icons.event, size: 18),
                      dropdownMenuEntries: _years
                          .map((y) => DropdownMenuEntry(value: y, label: y))
                          .toList(),
                      onSelected: (v) {
                        if (v != null) _selectYear(v);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 168,
                    child: DropdownMenu<int>(
                      key: ValueKey('month-$_selMonth-${_months.join(',')}'),
                      initialSelection: _selMonth,
                      enableSearch: false,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Month'),
                      leadingIcon: const Icon(Icons.calendar_month, size: 18),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: 0, label: 'Whole year'),
                        for (final m in _months)
                          DropdownMenuEntry(
                            value: m,
                            label: _monthNames[m - 1],
                          ),
                      ],
                      onSelected: (v) {
                        if (v != null) {
                          setState(() => _selMonth = v);
                          _applyMonthly();
                        }
                      },
                    ),
                  ),
                ] else
                  _buildCustom(theme, filter),
                if (_error != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 15, color: cs.error),
                      const SizedBox(width: 6),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 11.5, color: cs.error),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
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
        constraints: const BoxConstraints(minWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: hasRange ? cs.primaryContainer : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range,
              size: 18,
              color: hasRange ? cs.onPrimaryContainer : cs.onSurface,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: hasRange ? cs.onPrimaryContainer : cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Filter panel — the vertical sidebar holding the category checklist.
// ===========================================================================

/// Persistent vertical sidebar: a multi-select category checklist scoped to the
/// period currently selected in the [PeriodBar].
class FilterPanel extends ConsumerStatefulWidget {
  const FilterPanel({super.key});

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  final _db = DatabaseService();

  List<String> _categories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories(ref.read(filterProvider));
  }

  Future<void> _loadCategories(AppFilter f) async {
    try {
      final cats = await _db.getCategoriesForPeriod(filter: f);
      if (!mounted) return;
      setState(() {
        _error = null;
        _categories = cats;
      });
      // Drop any explicit selections that no longer exist in this period.
      if (!f.allCategories && f.categories.isNotEmpty) {
        final pruned = f.categories.where(cats.contains).toList();
        if (pruned.length != f.categories.length) {
          ref.read(filterProvider.notifier).setCategories(pruned, cats);
        }
      }
    } catch (e) {
      debugPrint('FilterPanel: failed to load categories: $e');
      if (!mounted) return;
      setState(
        () => _error = e is DatabaseNotConfiguredException
            ? 'No data source configured yet.'
            : 'Could not read the database.',
      );
    }
  }

  /// Small-caps sidebar section label ("CATEGORIES").
  Widget _sectionLabel(ThemeData theme, String text) => Text(
    text.toUpperCase(),
    style: theme.textTheme.labelSmall?.copyWith(
      fontSize: 10,
      letterSpacing: 0,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
    ),
  );

  /// Stable per-category accent drawn from the theme's chart palette, using the
  /// same name hash as the table's category pills so a category keeps one
  /// colour everywhere in the app.
  Color _categoryColor(String category) {
    final palette = appThemes[ref.read(themeIndexProvider)].palette;
    if (palette.isEmpty) return Theme.of(context).colorScheme.primary;
    final h = category.codeUnits.fold<int>(0, (s, c) => s + c);
    return palette[h % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filter = ref.watch(filterProvider);

    // Reload the category list whenever the selected period changes.
    ref.listen(filterProvider, (prev, next) {
      if (prev?.startDate != next.startDate || prev?.endDate != next.endDate) {
        _loadCategories(next);
      }
    });
    // Refresh the category options when the data source changes.
    ref.listen(
      dataReloadProvider,
      (_, _) => _loadCategories(ref.read(filterProvider)),
    );

    return Container(
      width: 288,
      decoration: BoxDecoration(
        // A slightly raised tone so the sidebar reads as its own zone instead
        // of blending into the content surface.
        color: cs.surfaceContainerLow,
        border: Border(right: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    size: 15,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (!filter.allCategories)
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(filterProvider.notifier).selectAllCategories(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 15),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(fontSize: 11.5, color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 16, 0),
            child: Row(
              children: [
                _sectionLabel(theme, 'Categories'),
                const Spacer(),
                if (filter.allCategories || filter.categories.isEmpty)
                  Text(
                    filter.allCategories ? 'All' : 'None',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  )
                else
                  // Standalone count badge; maxCount (Flutter 3.38) caps the
                  // label at 99+ if a database ever has that many categories.
                  Badge.count(
                    count: filter.categories.length,
                    maxCount: 99,
                    backgroundColor: cs.primary,
                    textColor: cs.onPrimary,
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

  Widget _buildCategoryList(ThemeData theme, AppFilter filter) {
    final cs = theme.colorScheme;
    final notifier = ref.read(filterProvider.notifier);
    final allSelected = filter.allCategories;
    final noneSelected = !filter.allCategories && filter.categories.isEmpty;
    // null => indeterminate (a partial selection).
    final bool? masterValue = allSelected
        ? true
        : (noneSelected ? false : null);

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
            child: Text(
              'No categories in this period',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          )
        else
          ..._categories.map(
            (c) => _categoryTile(
              theme,
              label: prettyCategory(c),
              icon: categoryIcon(c),
              dot: _categoryColor(c),
              value: filter.allCategories || filter.categories.contains(c),
              onChanged: () => notifier.toggleCategory(c, _categories),
            ),
          ),
      ],
    );
  }

  Widget _categoryTile(
    ThemeData theme, {
    required String label,
    required bool? value,
    required VoidCallback onChanged,
    FaIconData? icon,
    Color? dot,
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
                // Category icon in the category's stable accent colour.
                if (icon != null) ...[
                  SizedBox(
                    width: 20,
                    child: FaIcon(icon, size: 15, color: dot ?? cs.primary),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: (selected || bold)
                          ? FontWeight.w700
                          : FontWeight.w500,
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
