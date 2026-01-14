import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/providers/ui_provider.dart';
import 'package:money_app/screens/transactions_tab.dart';
import 'package:money_app/models/transaction.dart';
import 'package:money_app/models/category.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_search_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Search transactions filters the list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
          ChangeNotifierProvider(create: (_) => UiProvider()),
        ],
        child: const MoneyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigate to Transactions Tab
    await tester.tap(find.text('Movimientos'));
    await tester.pumpAndSettle();

    // 2. Add some dummy transactions if list is empty
    // The DataProvider might already have dummy data.
    // Let's assume there are transactions like "Comida", "Uber", etc.
    // Or we can add one via the UI or directly to provider if we had access.
    // Since we are in widget test, we can use the provider.

    final context = tester.element(find.byType(TransactionsTab));
    final provider = Provider.of<DataProvider>(context, listen: false);

    // Add Categories if needed
    try {
      provider.addCategory(name: 'Comida', kind: CategoryKind.expense);
    } catch (_) {
      // Ignore if already exists (dummy data)
    }
    
    try {
      provider.addCategory(name: 'Transporte', kind: CategoryKind.expense);
    } catch (_) {
      // Ignore
    }
    
    await tester.pumpAndSettle();

    // Get category IDs (case insensitive lookup or by known IDs)
    final foodCat = provider.categories.firstWhere((c) => c.name.toLowerCase() == 'comida');
    final transportCat = provider.categories.firstWhere((c) => c.name.toLowerCase() == 'transporte');

    // Add specific transactions for testing
    provider.addTransaction(
      amount: -50000,
      categoryId: foodCat.id,
      date: DateTime.now(),
      notes: 'Pizza Party',
      mainType: MainType.expenses,
      accountId: 'bank',
    );
    provider.addTransaction(
      amount: -20000,
      categoryId: transportCat.id,
      date: DateTime.now(),
      notes: 'Taxi to Airport',
      mainType: MainType.expenses,
      accountId: 'bank',
    );
    await tester.pumpAndSettle();

    // 3. Verify both are visible
    expect(find.text('Pizza Party'), findsOneWidget);
    expect(find.text('Taxi to Airport'), findsOneWidget);

    // 4. Search for "Pizza"
    await tester.enterText(find.byType(TextField), 'Pizza');
    await tester.pumpAndSettle();

    // 5. Verify filtering
    expect(find.text('Pizza Party'), findsOneWidget);
    expect(find.text('Taxi to Airport'), findsNothing);

    // 6. Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // 7. Verify all visible again
    expect(find.text('Pizza Party'), findsOneWidget);
    expect(find.text('Taxi to Airport'), findsOneWidget);
  });
}
