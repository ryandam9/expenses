import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expenses_dash/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ExpensesApp()));
    // The shell and filter sidebar render immediately, before any data loads.
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
  });
}
