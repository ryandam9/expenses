import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expenses_dash/models/app_filter.dart';
import 'package:expenses_dash/services/database_service.dart';

/// Integration tests for the SQL layer, run against a real (in-memory) SQLite
/// database so the queries — including the app-wide TRANSFERS exclusion — are
/// exercised end to end.
void main() {
  final svc = DatabaseService();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> seed() async {
    await svc.reopen(inMemoryDatabasePath);
    final db = await svc.database;
    await db.execute('''
      CREATE TABLE expenses (
        date TEXT, description TEXT, debit TEXT, credit TEXT,
        source TEXT, category TEXT
      )
    ''');
    final rows = [
      ['2023-12-01', 'Old coffee', '10', '0', 'BankB', 'FOOD'],
      ['2024-01-05', 'Groceries', '50', '0', 'BankA', 'FOOD'],
      ['2024-01-20', 'Salary', '0', '2000', 'BankA', 'INCOME'],
      ['2024-02-10', 'Rent', '900', '0', 'BankB', 'RENT'],
      // Transfers must be invisible to every query.
      ['2024-02-11', 'To savings', '500', '0', 'BankA', 'TRANSFERS'],
    ];
    for (final r in rows) {
      await db.insert('expenses', {
        'date': r[0],
        'description': r[1],
        'debit': r[2],
        'credit': r[3],
        'source': r[4],
        'category': r[5],
      });
    }
  }

  setUp(seed);
  tearDown(() => svc.reopen(''));

  test('throws DatabaseNotConfiguredException when no path is set', () async {
    await svc.reopen('');
    expect(svc.isConfigured, isFalse);
    expect(() => svc.database, throwsA(isA<DatabaseNotConfiguredException>()));
  });

  test('getExpenses excludes transfers and sorts by date descending', () async {
    final rows = await svc.getExpenses();
    expect(rows.length, 4);
    expect(rows.map((e) => e.category), isNot(contains('TRANSFERS')));
    expect(rows.first.date, '2024-02-10');
    expect(rows.last.date, '2023-12-01');
  });

  test('getExpenses applies date and category filters', () async {
    final rows = await svc.getExpenses(
        filter: const AppFilter(
            startDate: '2024-01-01',
            endDate: '2024-12-31',
            allCategories: false,
            categories: ['FOOD']));
    expect(rows.length, 1);
    expect(rows.single.description, 'Groceries');
  });

  test('getTotalDebits sums debits excluding transfers', () async {
    expect(await svc.getTotalDebits(), 960); // 10 + 50 + 900
    expect(
        await svc.getTotalDebits(
            filter:
                const AppFilter(startDate: '2024-01-01', endDate: '2024-01-31')),
        50);
  });

  test('getTotalCredits sums credits', () async {
    expect(await svc.getTotalCredits(), 2000);
  });

  test('getTransactionCount counts non-transfer rows', () async {
    expect(await svc.getTransactionCount(), 4);
  });

  test('getCategoriesForPeriod honours the date bounds only', () async {
    final cats = await svc.getCategoriesForPeriod(
        filter: const AppFilter(
            startDate: '2024-02-01',
            endDate: '2024-02-29',
            // Category selection must be ignored here.
            allCategories: false,
            categories: ['FOOD']));
    expect(cats, ['RENT']);
  });

  test('getYears returns distinct years, newest first', () async {
    expect(await svc.getYears(), ['2024', '2023']);
  });

  test('getMonthsForYear returns only months with data', () async {
    expect(await svc.getMonthsForYear('2024'), ['01', '02']);
    expect(await svc.getMonthsForYear('2023'), ['12']);
  });
}
