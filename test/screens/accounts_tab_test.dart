import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:money_app/models/account.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/screens/accounts_tab.dart';
import 'package:money_app/utils/constants.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    // Create a temporary directory for Hive
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_accounts_test_');
    Hive.init(hiveTestDir.path);
    // Register adapters if needed (Account, etc.) - assuming they are registered in DataProvider or main
    // But since we are using DataProvider which initializes Hive boxes, we might need to mock or ensure adapters are registered.
    // For unit tests usually we mock, but here we are doing integration widget test.
    // Let's assume DataProvider.ensureInitialized() or similar is called, or we manually register.
    // Actually, DataProvider constructor might not open boxes immediately or might need initialization.
    // Checking DataProvider...
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('AccountsTab shows red gradient for negative total balance', (WidgetTester tester) async {
    final dataProvider = DataProvider();
    // We need to initialize Hive boxes for DataProvider to work if it relies on them.
    // For simplicity, let's try to mock the data if possible, or just use the provider.
    // Since DataProvider uses Hive, we need to be careful.
    // Let's rely on the fact that `widget_test.dart` worked with `DataProvider()`.
    
    // Add an account with negative balance
    dataProvider.addAccount(
      name: 'Debt', 
      type: AccountType.bank, 
      initialBalance: -100000
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DataProvider>.value(
            value: dataProvider,
            child: const AccountsTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the container with the "Balance Total" text
    final balanceTextFinder = find.text('Balance Total');
    expect(balanceTextFinder, findsOneWidget);

    // The container is the parent of the Column that contains this text.
    // The structure is Container -> Column -> Row -> [Icon, Text('Balance Total')]
    // So we need to find the Container.
    // Let's find the Container by its decoration.
    
    final containerFinder = find.descendant(
      of: find.byType(ListView),
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.gradient == AppGradients.error;
        }
        return false;
      }),
    );

    expect(containerFinder, findsOneWidget);
  });
}
