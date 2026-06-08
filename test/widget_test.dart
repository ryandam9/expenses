import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_dash/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpensesApp());
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
