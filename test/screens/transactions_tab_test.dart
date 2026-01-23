import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:money_app/screens/transactions_tab.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/models/transaction.dart';
import 'package:money_app/models/account.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    await initializeDateFormatting('es_ES', null);
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_transactions_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('TransactionsTab toggles between List and Calendar view', (WidgetTester tester) async {
    final dataProvider = DataProvider();
    
    // Add some dummy data
    dataProvider.addAccount(name: 'Test Bank', type: AccountType.bank, initialBalance: 100000);
    // We need categories to add transactions usually, but DataProvider might have defaults or we can add one.
    // DataProvider constructor might add default categories if box is empty.
    // Let's assume we can add a transaction if we have valid IDs.
    // Actually DataProvider.addTransaction requires categoryId and accountId.
    
    // Mocking DataProvider or just using it as is. 
    // Since we are not testing data logic but UI switching, empty list is fine too.
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DataProvider>.value(
            value: dataProvider,
            child: const TransactionsTab(),
          ),
        ),
      ),
    );

    // Initial state: List View
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    // expect(find.byType(ListView), findsOneWidget); // Empty state doesn't use ListView
    
    // Check if empty state is shown (since no transactions)
    expect(find.text('No hay movimientos'), findsOneWidget);

    // Tap toggle
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    // Calendar View
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byType(TableCalendar<Transaction>), findsOneWidget);
    
    // Tap toggle back
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
    
    // Back to List View
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    expect(find.text('No hay movimientos'), findsOneWidget);
  });
}
