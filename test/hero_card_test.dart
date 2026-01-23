import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/widgets/hero_card.dart';

void main() {
  testWidgets('HeroCard displays correct info for positive amount', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeroCard(amount: 50000),
        ),
      ),
    );

    expect(find.text('Te sobraría'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });

  testWidgets('HeroCard displays correct info for negative amount', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeroCard(amount: -80000),
        ),
      ),
    );

    expect(find.text('Te faltaría'), findsOneWidget);
    expect(find.byIcon(Icons.trending_down), findsOneWidget);
  });
}
