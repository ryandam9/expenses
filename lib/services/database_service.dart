import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/app_filter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;
  DatabaseService._();

  Database? _db;

  static const _dbPath =
      '/home/ravi/Desktop/temp/statements/output/expenses.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final file = File(_dbPath);
    final exists = await file.exists();
    if (!exists) {
      throw Exception('Database not found at $_dbPath');
    }
    return await openDatabase(_dbPath);
  }

  // Transfers between a user's own accounts aren't real income or spending,
  // so this category is excluded from every query, app-wide.
  static const _excludeTransfers = "UPPER(category) <> 'TRANSFERS'";

  String? _whereClause(AppFilter f) {
    final clauses = <String>[_excludeTransfers];
    if (f.startDate != null) {
      clauses.add('date >= ?');
    }
    if (f.endDate != null) {
      clauses.add('date <= ?');
    }
    if (!f.allCategories) {
      if (f.categories.isEmpty) {
        // Explicit "none selected" -> match no rows.
        clauses.add('1 = 0');
      } else {
        clauses.add('category IN (${f.categories.map((_) => '?').join(', ')})');
      }
    }
    return clauses.join(' AND ');
  }

  List<String> _whereArgs(AppFilter f) {
    final args = <String>[];
    if (f.startDate != null) args.add(f.startDate!);
    if (f.endDate != null) args.add(f.endDate!);
    if (!f.allCategories && f.categories.isNotEmpty) args.addAll(f.categories);
    return args;
  }

  Future<List<Expense>> getExpenses(
      {int? limit, int? offset, AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final rows = await db.query('expenses',
        where: where,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'date DESC',
        limit: limit,
        offset: offset);
    return rows.map((r) => Expense.fromMap(r)).toList();
  }

  Future<double> getTotalDebits({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('SELECT SUM(CAST(debit AS REAL)) as total FROM expenses WHERE CAST(debit AS REAL) > 0');
    if (where != null) buf.write(' AND $where');
    final result = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalCredits({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('SELECT SUM(CAST(credit AS REAL)) as total FROM expenses WHERE CAST(credit AS REAL) > 0');
    if (where != null) buf.write(' AND $where');
    final result = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getTransactionCount({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('SELECT COUNT(*) as count FROM expenses');
    if (where != null) buf.write(' WHERE $where');
    final result = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return (result.first['count'] as num).toInt();
  }

  Future<Map<String, double>> getSpendByCategory({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('''
      SELECT category, SUM(CAST(debit AS REAL)) as total
      FROM expenses
      WHERE CAST(debit AS REAL) > 0
    ''');
    if (where != null) buf.write(' AND $where');
    buf.write(' GROUP BY category ORDER BY total DESC');
    final rows = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return {
      for (var r in rows)
        r['category'] as String: (r['total'] as num).toDouble()
    };
  }

  Future<Map<String, double>> getMonthlySpending({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('''
      SELECT substr(date, 1, 7) as month, SUM(CAST(debit AS REAL)) as total
      FROM expenses
      WHERE CAST(debit AS REAL) > 0
    ''');
    if (where != null) buf.write(' AND $where');
    buf.write(' GROUP BY month ORDER BY month ASC');
    final rows = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return {
      for (var r in rows)
        r['month'] as String: (r['total'] as num).toDouble()
    };
  }

  Future<Map<String, double>> getSpendBySource({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('''
      SELECT source, SUM(CAST(debit AS REAL)) as total
      FROM expenses
      WHERE CAST(debit AS REAL) > 0
    ''');
    if (where != null) buf.write(' AND $where');
    buf.write(' GROUP BY source ORDER BY total DESC');
    final rows = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return {
      for (var r in rows)
        r['source'] as String: (r['total'] as num).toDouble()
    };
  }

  Future<Map<String, int>> getCategoryCount({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final where = _whereClause(f);
    final args = _whereArgs(f);
    final buf = StringBuffer('''
      SELECT category, COUNT(*) as count
      FROM expenses
      WHERE CAST(debit AS REAL) > 0
    ''');
    if (where != null) buf.write(' AND $where');
    buf.write(' GROUP BY category ORDER BY count DESC');
    final rows = await db.rawQuery(buf.toString(), args.isNotEmpty ? args : null);
    return {
      for (var r in rows)
        r['category'] as String: (r['count'] as num).toInt()
    };
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM expenses WHERE $_excludeTransfers ORDER BY category');
    return rows.map((r) => r['category'] as String).toList();
  }

  /// Distinct categories that have transactions within the selected period.
  /// Only the date bounds of [filter] are applied (category selection is
  /// ignored, so the full set of options for the period is returned).
  Future<List<String>> getCategoriesForPeriod({AppFilter? filter}) async {
    final db = await database;
    final f = filter ?? const AppFilter();
    final clauses = <String>[_excludeTransfers];
    final args = <String>[];
    if (f.startDate != null) {
      clauses.add('date >= ?');
      args.add(f.startDate!);
    }
    if (f.endDate != null) {
      clauses.add('date <= ?');
      args.add(f.endDate!);
    }
    final where = 'WHERE ${clauses.join(' AND ')}';
    final rows = await db.rawQuery(
        'SELECT DISTINCT category FROM expenses $where ORDER BY category',
        args.isNotEmpty ? args : null);
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<List<String>> getSources() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT source FROM expenses ORDER BY source');
    return rows.map((r) => r['source'] as String).toList();
  }

  Future<List<String>> getYears() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT substr(date, 1, 4) as yr FROM expenses ORDER BY yr DESC');
    return rows.map((r) => r['yr'] as String).toList();
  }

  Future<List<String>> getMonthsForYear(String year) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT DISTINCT substr(date, 6, 2) as mo FROM expenses WHERE date LIKE ? ORDER BY mo',
        ['$year-%']);
    return rows.map((r) => r['mo'] as String).toList();
  }
}
