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

    // The shell and the default Summary dashboard render immediately, before
    // any data loads. (The Transactions filter sidebar lives on an offstage
    // IndexedStack page, which find.text skips by default.)
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
  });

  testWidgets('collapsing and expanding the sidebar does not overflow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const ExpensesApp(),
      ),
    );

    // Collapse: pump through the width animation, asserting it stays clean —
    // an overflowing RenderFlex would surface via takeException().
    await tester.tap(find.text('Collapse'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Once collapsed the labels are gone: the brand text and the toggle's
    // "Collapse" label are replaced by an icon-only control.
    expect(find.text('Expenses'), findsNothing);
    expect(find.text('Collapse'), findsNothing);
    expect(find.byTooltip('Expand sidebar'), findsOneWidget);

    // Expand again (the toggle is now an icon-only button with a tooltip).
    await tester.tap(find.byTooltip('Expand sidebar'));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Collapse'), findsOneWidget);
  });
}
