import 'package:expenses_dash/widgets/insights_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InsightsCarousel does not overflow in compressed layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              child: InsightsCarousel(
                items: [
                  InsightItem(
                    label: 'Spend pulse',
                    value: r'$12,345',
                    detail: 'A long period label that must fit',
                    icon: Icons.query_stats_rounded,
                    color: Colors.red,
                  ),
                  InsightItem(
                    label: 'Top category',
                    value: 'Groceries and supermarkets',
                    detail: r'$3,210',
                    icon: Icons.category_rounded,
                    color: Colors.blue,
                  ),
                  InsightItem(
                    label: 'Largest expense',
                    value: r'$999',
                    detail: 'Long merchant description that must ellipsize',
                    icon: Icons.priority_high_rounded,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
