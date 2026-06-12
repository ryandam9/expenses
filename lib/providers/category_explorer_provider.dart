import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_filter.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import 'prefs_provider.dart';

/// The category explorer's selection: one or more categories, plus an
/// optional date range. Unlike the dashboard filter, the default is the
/// entire history — a period only applies when explicitly chosen.
class CategoryExplorerState {
  final Set<String> selected;
  final String? startDate;
  final String? endDate;

  const CategoryExplorerState({
    this.selected = const {},
    this.startDate,
    this.endDate,
  });

  bool get hasPeriod => startDate != null && endDate != null;

  /// The [AppFilter] equivalent of this selection, for the SQL layer.
  AppFilter toFilter() => AppFilter(
        startDate: startDate,
        endDate: endDate,
        categories: selected.toList(),
        allCategories: false,
      );
}

class CategoryExplorerNotifier extends Notifier<CategoryExplorerState> {
  @override
  CategoryExplorerState build() => const CategoryExplorerState();

  void toggle(String category) {
    final next = Set<String>.from(state.selected);
    if (!next.remove(category)) next.add(category);
    state = CategoryExplorerState(
        selected: next, startDate: state.startDate, endDate: state.endDate);
  }

  void clearSelection() {
    state = CategoryExplorerState(
        startDate: state.startDate, endDate: state.endDate);
  }

  void setPeriod(String start, String end) {
    state = CategoryExplorerState(
        selected: state.selected, startDate: start, endDate: end);
  }

  void clearPeriod() {
    state = CategoryExplorerState(selected: state.selected);
  }
}

final categoryExplorerProvider =
    NotifierProvider<CategoryExplorerNotifier, CategoryExplorerState>(
        CategoryExplorerNotifier.new);

/// Every category in the database with its all-time spend and transaction
/// count. Refreshed when the data source changes.
final categorySummariesProvider = FutureProvider<List<CategorySummary>>(
    retry: (_, _) => null, (ref) async {
  ref.watch(dataReloadProvider);
  ref.watch(dbPathProvider);
  return DatabaseService().getCategorySummaries();
});

/// The transactions matching the explorer's selection (empty selection ->
/// no rows, so the screen can show its pick-something hint instead).
final categoryTransactionsProvider = FutureProvider<List<Expense>>(
    retry: (_, _) => null, (ref) async {
  ref.watch(dataReloadProvider);
  ref.watch(dbPathProvider);
  final s = ref.watch(categoryExplorerProvider);
  if (s.selected.isEmpty) return const <Expense>[];
  return DatabaseService().getExpenses(filter: s.toFilter());
});
