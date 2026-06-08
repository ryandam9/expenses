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
