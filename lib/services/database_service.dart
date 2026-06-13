import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/app_filter.dart';
import 'query_builder.dart';

/// Thrown when no database file has been chosen yet (fresh install). The
/// dashboard recognises this and shows a first-run setup screen instead of a
/// generic error.
class DatabaseNotConfiguredException implements Exception {
  @override
  String toString() => 'No data source configured';
}

/// A category's all-time figures, for the category explorer list.
typedef CategorySummary = ({String category, double total, int count});

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Database? _db;

  /// The configured database path. Set at startup from saved settings and
  /// changed at runtime via [reopen]. Null until the user picks a file.
  static String? overridePath;

  String? get currentPath => overridePath;

  bool get isConfigured =>
      overridePath != null && overridePath!.trim().isNotEmpty;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = currentPath;
    if (path == null || path.trim().isEmpty) {
      throw DatabaseNotConfiguredException();
    }
    // ':memory:' (used by tests) never exists on disk, so skip the check.
    if (path != inMemoryDatabasePath && !await File(path).exists()) {
      throw Exception('Database not found at $path');
    }
    return await openDatabase(path);
  }

  /// Points the service at a new database file and drops the open connection so
  /// the next query reopens against [path]. An empty path de-configures the
  /// service (back to the first-run state).
  Future<void> reopen(String path) async {
    overridePath = path.trim().isEmpty ? null : path.trim();
    // Drop the cached handle *before* awaiting the close. A query that races in
    // while the old connection is still closing would otherwise see a non-null
    // [_db] and reuse it, rendering the previous database's transactions.
    // Clearing it first means any such query reopens against [overridePath].
    // Nulling first also guarantees the handle is released even if close()
    // throws (e.g. an operation was in flight on it).
    final previous = _db;
    _db = null;
    await previous?.close();
  }

  // Delegates to the pure, unit-tested builder in query_builder.dart. The
  // clause always excludes the TRANSFERS category.
  String? _whereClause(AppFilter f) => buildWhere(f).clause;

  List<String> _whereArgs(AppFilter f) => buildWhere(f).args;

  /// All rows matching [filter]. Deliberately unpaginated: the dataset is a
  /// few thousand rows, and loading it once enables instant client-side
  /// search/sort/pagination plus in-memory aggregation for the KPIs and
  /// charts. Revisit (limit/offset) only if datasets grow well beyond that.
  Future<List<Expense>> getExpenses({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final rows = await db.query('expenses',
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'date DESC');
    return rows.map((r) => Expense.fromMap(r)).toList();
  }

  /// SUM of debits for [filter]. Kept as a SQL aggregate (rather than derived
  /// from [getExpenses]) because it is also used for previous-period
  /// comparisons, where fetching all the rows would be wasteful.
  Future<double> getTotalDebits({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer(
        'SELECT SUM(CAST(debit AS REAL)) as total FROM expenses WHERE CAST(debit AS REAL) > 0');
    if (where != null) buf.write(' AND $where');
    final result =
        await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalCredits({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer(
        'SELECT SUM(CAST(credit AS REAL)) as total FROM expenses WHERE CAST(credit AS REAL) > 0');
    if (where != null) buf.write(' AND $where');
    final result =
        await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTransactionCount({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('SELECT COUNT(*) as count FROM expenses');
    if (where != null) buf.write(' WHERE $where');
    final result =
        await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return (result.first['count'] as num).toInt();
  }

  /// Distinct categories that have transactions within the selected period.
  /// Only the date bounds of [filter] are applied (category selection is
  /// ignored, so the full set of options for the period is returned).
  Future<List<String>> getCategoriesForPeriod({AppFilter? filter}) async {
    final db = await database;
    final where = buildDateWhere(filter ?? const AppFilter());
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM expenses WHERE ${where.clause} ORDER BY category',
        where.args.isNotEmpty ? where.args : null);
    return rows.map((r) => r['category'] as String).toList();
  }

  /// One row per category over the entire history (transfers excluded):
  /// total spend (sum of debits) and transaction count, highest spend first.
  /// Backs the category explorer's list.
  Future<List<CategorySummary>> getCategorySummaries() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT category, '
        'SUM(CASE WHEN CAST(debit AS REAL) > 0 THEN CAST(debit AS REAL) ELSE 0 END) AS total, '
        'COUNT(*) AS cnt '
        'FROM expenses WHERE $excludeTransfersClause '
        'GROUP BY category ORDER BY total DESC, category');
    return [
      for (final r in rows)
        (
          category: r['category'] as String,
          total: (r['total'] as num?)?.toDouble() ?? 0,
          count: (r['cnt'] as num).toInt(),
        ),
    ];
  }

  Future<List<String>> getYears() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT substr(date, 1, 4) as yr FROM expenses ORDER BY yr DESC');
    return rows.map((r) => r['yr'] as String).toList();
  }

  /// Distinct months ('01'..'12') that actually have data in [year], so the
  /// filter sidebar can hide empty months.
  Future<List<String>> getMonthsForYear(String year) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT substr(date, 6, 2) as mo FROM expenses WHERE date LIKE ? ORDER BY mo',
        ['$year-%']);
    return rows.map((r) => r['mo'] as String).toList();
  }
}
