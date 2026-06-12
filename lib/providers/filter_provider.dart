import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_filter.dart';
import '../utils/format.dart';

class FilterNotifier extends Notifier<AppFilter> {
  @override
  AppFilter build() => const AppFilter();

  void apply(AppFilter f) => state = f;

  void clearAll() => state = const AppFilter();

  void setPeriod({String? startDate, String? endDate}) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  /// Sets the period explicitly, allowing nulls to clear either bound while
  /// preserving the current category selection.
  void setRange(String? startDate, String? endDate) {
    state = AppFilter(
      startDate: startDate,
      endDate: endDate,
      categories: state.categories,
      allCategories: state.allCategories,
    );
  }

  /// Master toggle: select every category (no filter) or select none.
  void selectAllCategories() =>
      state = state.copyWith(allCategories: true, categories: []);

  void selectNoCategories() =>
      state = state.copyWith(allCategories: false, categories: []);

  /// Toggles a single category. [allCats] is the full set of options for the
  /// current period so the selection can normalise to "all" or "none".
  void toggleCategory(String category, List<String> allCats) {
    // Resolve the current explicit selection (when "all", that is everything).
    final current = state.allCategories
        ? List<String>.from(allCats)
        : List<String>.from(state.categories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    _commit(current, allCats);
  }

  /// Replaces the explicit selection, normalising the edge cases.
  void setCategories(List<String> cats, List<String> allCats) =>
      _commit(cats, allCats);

  void _commit(List<String> selection, List<String> allCats) {
    if (allCats.isNotEmpty && selection.length >= allCats.length) {
      state = state.copyWith(allCategories: true, categories: []);
    } else {
      state = state.copyWith(allCategories: false, categories: selection);
    }
  }

  String get periodLabel {
    final f = state;
    if (!f.hasPeriod) return 'All Time';
    final s = f.startDate;
    final e = f.endDate;
    if (s == e && s != null) {
      final parts = s.split('-');
      if (parts.length >= 2) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final m = int.tryParse(parts[1]) ?? 0;
        if (m >= 1 && m <= 12) return '${months[m - 1]} ${parts[0]}';
        return parts[0];
      }
      return s;
    }
    return '$s – $e';
  }

  String get categoriesLabel {
    final f = state;
    if (f.allCategories) return 'All';
    if (f.categories.isEmpty) return 'None';
    if (f.categories.length == 1) {
      return prettyCategory(f.categories.first);
    }
    return '${f.categories.length} selected';
  }
}

final filterProvider = NotifierProvider<FilterNotifier, AppFilter>(FilterNotifier.new);
