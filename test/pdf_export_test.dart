import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_dash/models/expense.dart';
import 'package:expenses_dash/services/pdf_export.dart';

Expense _e(String date, double debit, String category, [String bank = 'ANZ']) =>
    Expense(
      date: date,
      description: '$category payment at store',
      debit: debit,
      credit: 0,
      source: bank,
      category: category,
    );

void main() {
  final rows = [
    _e('2026-06-02', 2000, 'RENT'),
    _e('2026-06-01', 120, 'GROCERIES'),
    _e('2026-06-05', 60, 'TRANSPORT'),
    _e('2026-05-20', 80, 'GROCERIES'),
    _e('2026-06-09', 45, 'ENTERTAINMENT'),
  ];

  test('builds a non-empty, valid PDF document', () async {
    final bytes = await buildExpensesPdf(rows: rows, periodLabel: 'All time');
    expect(bytes, isNotEmpty);
    // Every PDF file starts with the "%PDF" magic header.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('handles an empty selection without throwing', () async {
    final bytes = await buildExpensesPdf(rows: [], periodLabel: 'All time');
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('file name uses the latest month present (YYYY-MM-Expenses.pdf)', () {
    expect(expensesPdfFileName(rows), '2026-06-Expenses.pdf');
  });
}
