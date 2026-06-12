import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_dash/models/app_filter.dart';
import 'package:expenses_dash/models/expense.dart';
import 'package:expenses_dash/services/query_builder.dart';

void main() {
  group('buildWhere', () {
    test('always excludes transfers', () {
      final r = buildWhere(const AppFilter());
      expect(r.clause, contains("UPPER(category) <> 'TRANSFERS'"));
      expect(r.args, isEmpty);
    });

    test('adds date bounds with args in order', () {
      final r = buildWhere(
          const AppFilter(startDate: '2024-01-01', endDate: '2024-12-31'));
      expect(r.clause, contains('date >= ?'));
      expect(r.clause, contains('date <= ?'));
      expect(r.args, ['2024-01-01', '2024-12-31']);
    });

    test('explicit "none selected" matches no rows', () {
      final r =
          buildWhere(const AppFilter(allCategories: false, categories: []));
      expect(r.clause, contains('1 = 0'));
    });

    test('category IN clause has matching placeholders and args', () {
      final r = buildWhere(const AppFilter(
          allCategories: false, categories: ['food', 'rent']));
      expect(r.clause, contains('category IN (?, ?)'));
      expect(r.args, ['food', 'rent']);
    });
  });

  group('buildDateWhere', () {
    test('ignores category selection', () {
      final r = buildDateWhere(const AppFilter(
          startDate: '2024-02-01',
          endDate: '2024-02-29',
          allCategories: false,
          categories: ['food']));
      expect(r.clause, isNot(contains('category IN')));
      expect(r.clause, contains("UPPER(category) <> 'TRANSFERS'"));
      expect(r.args, ['2024-02-01', '2024-02-29']);
    });
  });

  group('previousPeriod', () {
    test('whole calendar month compares with the previous month', () {
      final p = previousPeriod(
          const AppFilter(startDate: '2024-03-01', endDate: '2024-03-31'));
      expect(p!.startDate, '2024-02-01');
      expect(p.endDate, '2024-02-29'); // 2024 is a leap year
    });

    test('January wraps into December of the previous year', () {
      final p = previousPeriod(
          const AppFilter(startDate: '2024-01-01', endDate: '2024-01-31'));
      expect(p!.startDate, '2023-12-01');
      expect(p.endDate, '2023-12-31');
    });

    test('whole calendar year compares with the previous year', () {
      final p = previousPeriod(
          const AppFilter(startDate: '2024-01-01', endDate: '2024-12-31'));
      expect(p!.startDate, '2023-01-01');
      expect(p.endDate, '2023-12-31');
    });

    test('arbitrary range shifts back by its own length', () {
      final p = previousPeriod(
          const AppFilter(startDate: '2024-05-11', endDate: '2024-05-20'));
      expect(p!.startDate, '2024-05-01');
      expect(p.endDate, '2024-05-10');
    });

    test('returns null without a complete range', () {
      expect(previousPeriod(const AppFilter()), isNull);
      expect(previousPeriod(const AppFilter(startDate: '2024-01-01')), isNull);
    });

    test('preserves the category selection', () {
      final p = previousPeriod(const AppFilter(
          startDate: '2024-03-01',
          endDate: '2024-03-31',
          allCategories: false,
          categories: ['food']));
      expect(p!.allCategories, isFalse);
      expect(p.categories, ['food']);
    });
  });

  group('debitTotalsBy', () {
    Expense tx(String cat, double debit, double credit) => Expense(
        date: '2024-01-01',
        description: 'x',
        debit: debit,
        credit: credit,
        source: 'Bank',
        category: cat);

    test('sums debits per key, sorted high to low, ignoring credits', () {
      final totals = debitTotalsBy([
        tx('food', 10, 0),
        tx('rent', 100, 0),
        tx('food', 5, 0),
        tx('income', 0, 500),
      ], (e) => e.category);
      expect(totals.keys.toList(), ['rent', 'food']);
      expect(totals['rent'], 100);
      expect(totals['food'], 15);
    });
  });

  group('csv helpers', () {
    test('csvField escapes commas, quotes and newlines', () {
      expect(csvField('plain'), 'plain');
      expect(csvField('a,b'), '"a,b"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('line1\nline2'), '"line1\nline2"');
    });

    test('transactionsToCsv writes a header and one row per expense', () {
      final csv = transactionsToCsv([
        Expense(
            date: '2024-01-01',
            description: 'Coffee, large',
            debit: 4.5,
            credit: 0,
            source: 'Bank',
            category: 'food'),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.first,
          'Date,Description,Bank,Debit,Credit,Amount,Category');
      // Description has a comma so it must be quoted.
      expect(lines[1], contains('"Coffee, large"'));
    });

    test('categorySummaryToCsv sorts high-to-low and adds percentages', () {
      final csv = categorySummaryToCsv({'food': 30, 'rent': 70});
      final lines = csv.trim().split('\n');
      expect(lines.first, 'Category,Total,Percent');
      expect(lines[1], startsWith('rent,70.00,70.0%'));
      expect(lines[2], startsWith('food,30.00,30.0%'));
    });
  });
}
