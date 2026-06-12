import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/database_service.dart';
import '../services/query_builder.dart';
import 'filter_provider.dart';
import 'prefs_provider.dart';

/// Everything the dashboard needs for the active filter, loaded in one go.
class DashboardData {
  final List<Expense> transactions;

  /// Totals for the equivalent previous period (previous month/year for whole
  /// calendar selections, otherwise the same-length range immediately before).
  /// Null when the current filter has no complete date range to compare with.
  final double? prevDebits;
  final double? prevCredits;

  const DashboardData({
    required this.transactions,
    this.prevDebits,
    this.prevCredits,
  });
}

/// Loads the dashboard's data for the active filter. Re-runs automatically
/// when the filter or the data source changes; while reloading, Riverpod keeps
/// the previous value available so the UI can show stale data behind a thin
/// progress bar instead of flashing a full-screen spinner.
final dashboardDataProvider = FutureProvider<DashboardData>(
    // A missing/unconfigured database isn't transient — surface it immediately
    // instead of letting Riverpod's default backoff retry it forever.
    retry: (_, _) => null, (ref) async {
  ref.watch(dataReloadProvider);
  ref.watch(dbPathProvider);
  final filter = ref.watch(filterProvider);
  final db = DatabaseService();

  final transactions = await db.getExpenses(filter: filter);

  double? prevDebits;
  double? prevCredits;
  final prev = previousPeriod(filter);
  if (prev != null) {
    prevDebits = await db.getTotalDebits(filter: prev);
    prevCredits = await db.getTotalCredits(filter: prev);
  }
  return DashboardData(
    transactions: transactions,
    prevDebits: prevDebits,
    prevCredits: prevCredits,
  );
});

/// Live, unfiltered transaction count (excluding transfers); shown in
/// Settings → About.
final transactionCountProvider = FutureProvider<int>(
    retry: (_, _) => null, (ref) async {
  ref.watch(dataReloadProvider);
  ref.watch(dbPathProvider);
  return DatabaseService().getTransactionCount();
});
