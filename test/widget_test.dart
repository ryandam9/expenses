import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expenses_dash/main.dart';
import 'package:expenses_dash/providers/prefs_provider.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ExpensesApp(),
      ),
    );

    // The shell and filter sidebar render immediately, before any data loads.
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
  });
}
