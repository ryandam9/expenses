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
      final cats = await _db.getCategories();
      final years = await _db.getYears();
      if (mounted) {
        setState(() {
          _categories = cats;
          _years = years;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickMonth(BuildContext context) async {
    if (_years.isEmpty) return;
    String selectedYear = _years.first;

    final result = await showDialog<({String year, int month})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              icon: const Icon(Icons.calendar_month),
              title: const Text('Select Month'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownMenu<String>(
                      initialSelection: selectedYear,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Year'),
                      dropdownMenuEntries: _years
                          .map((y) => DropdownMenuEntry(value: y, label: y))
                          .toList(),
                      onSelected: (v) {
                        if (v != null) setLocal(() => selectedYear = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.0,
                      children: List.generate(12, (i) {
                        return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                                color: theme.colorScheme.primary, width: 1.5),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero),
                          ),
                          onPressed: () => Navigator.pop(
                              ctx, (year: selectedYear, month: i + 1)),
                          child: Text(
                            _monthNames[i],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final mm = result.month.toString().padLeft(2, '0');
      final lastDay = DateTime(int.parse(result.year), result.month + 1, 0).day;
      final start = '${result.year}-$mm-01';
      final end = '${result.year}-$mm-${lastDay.toString().padLeft(2, '0')}';
      ref.read(filterProvider.notifier).setPeriod(startDate: start, endDate: end);
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final filter = ref.read(filterProvider);
    final currentDate = isStart ? filter.startDate : filter.endDate;
    
    DateTime initial = DateTime.now();
    if (currentDate != null) {
      final parts = currentDate.split('-');
      if (parts.length == 3) {
        initial = DateTime(
          int.tryParse(parts[0]) ?? DateTime.now().year,
          int.tryParse(parts[1]) ?? 1,
          int.tryParse(parts[2]) ?? 1,
        );
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Select Start Date' : 'Select End Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              headerBackgroundColor: Theme.of(context).colorScheme.primary,
              headerForegroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final notifier = ref.read(filterProvider.notifier);
      if (isStart) {
        notifier.setPeriod(startDate: formatted, endDate: filter.endDate);
      } else {
        notifier.setPeriod(startDate: filter.startDate, endDate: formatted);
      }
    }
  }

  void _clear() {
    setState(() => _catExpanded = false);
    ref.read(filterProvider.notifier).clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider);
    final hasFilter = filter.hasPeriod || filter.hasCategories;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MonthButton(onTap: () => _pickMonth(context)),
              const SizedBox(width: 8),
              Expanded(
                child: _DateButton(
                  label: 'Start',
                  date: filter.startDate,
                  onPickDate: () => _pickDate(context, true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('-', style: TextStyle(fontSize: 18)),
              ),
              Expanded(
                child: _DateButton(
                  label: 'End',
                  date: filter.endDate,
                  onPickDate: () => _pickDate(context, false),
                ),
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(theme, filter),
              if (hasFilter) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  tooltip: 'Clear filters',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          if (_catExpanded) _buildCategoryPanel(theme, filter),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          color: filter.hasCategories
              ? theme.colorScheme.primary
              : Colors.transparent,
          borderRadius: _catExpanded ? const BorderRadius.vertical(top: Radius.circular(4)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: filter.hasCategories,
              child: Icon(
                Icons.category,
                size: 14,
                color: filter.hasCategories
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: filter.hasCategories
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _catExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
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
    return Card.outlined(
      margin: const EdgeInsets.only(top: 2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
        side: BorderSide(width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Select Categories', style: theme.textTheme.labelLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    ref.read(filterProvider.notifier).setCategories([]);
                  },
                  icon: const Icon(Icons.clear_all, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _categories.map((c) {
                final selected = filter.categories.contains(c);
                return AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: selected ? 1.05 : 1.0,
                  child: FilterChip(
                    avatar: selected
                        ? Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary)
                        : null,
                    label: Text(
                      c.replaceAll('-', ' ').toLowerCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      ref.read(filterProvider.notifier).toggleCategory(c);
                    },
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MonthButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 14, color: theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              'Month',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String? date;
  final VoidCallback onPickDate;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = date != null && date!.isNotEmpty;
    
    return InkWell(
      onTap: onPickDate,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          color: hasDate ? theme.colorScheme.primaryContainer : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: hasDate 
                  ? theme.colorScheme.onPrimaryContainer 
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: hasDate 
                          ? theme.colorScheme.onPrimaryContainer 
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    hasDate ? date! : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDate 
                          ? theme.colorScheme.onPrimaryContainer 
                          : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: hasDate 
                  ? theme.colorScheme.onPrimaryContainer 
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
