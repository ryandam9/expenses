import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expenses_dash/models/expense.dart';
import 'package:expenses_dash/providers/dashboard_provider.dart';
import 'package:expenses_dash/providers/prefs_provider.dart';
import 'package:expenses_dash/screens/summary_screen.dart';

Expense _e(String date, double debit, double credit, String category) =>
    Expense(
      date: date,
      description: '$category spend',
      debit: debit,
      credit: credit,
      source: 'test',
      category: category,
    );

Future<void> _pump(WidgetTester tester, List<Expense> data) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allExpensesProvider.overrideWith((ref) async => data),
      ],
      child: const MaterialApp(home: SummaryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('groups the latest month by category, high to low', (
    tester,
  ) async {
    await _pump(tester, [
      _e('2026-06-02', 2000, 0, 'RENT'),
      _e('2026-06-01', 100, 0, 'GROCERIES'),
      _e('2026-06-03', 0, 5000, 'INCOME'),
      _e('2026-05-10', 50, 0, 'GROCERIES'), // an earlier month, excluded
    ]);

    // The category section and both spending categories render (each name
    // shows in the composition legend and again on its ranked card).
    expect(find.text('Expenses per Category'), findsOneWidget);
    expect(find.text('Rent'), findsWidgets);
    expect(find.text('Groceries'), findsWidgets);

    // Total spent is the sum of the latest month's debits (2000 + 100), and
    // the earlier month's $50 is not counted.
    expect(find.text('\$2,100.00'), findsOneWidget);

    // The top category leads the ranking.
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no transactions', (
    tester,
  ) async {
    await _pump(tester, []);
    expect(find.text('No transactions yet'), findsOneWidget);
  });
}
