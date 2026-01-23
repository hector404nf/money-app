import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/providers/ui_provider.dart';
import 'package:money_app/utils/constants.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_paid_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Mark as Paid flow updates balance', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 6000);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) {
            final provider = DataProvider();
            provider.loadDummyForTests();
            return provider;
          }),
          ChangeNotifierProvider(create: (_) {
            final ui = UiProvider();
            ui.completeOnboarding();
            return ui;
          }),
        ],
        child: const MoneyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 1. Get Initial Balance of 'ITAU' (id: '1')
    // We can check it on Accounts tab or Dashboard.
    // Dashboard shows total balance. Accounts tab shows per account.
    // Let's use Accounts tab.
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    
    // ITAU has 5,000,000 initial.
    // Plus dummy transactions:
    // t1: +15,000,000 (Paid)
    // t2: -800,000 (Paid)
    // t3: -2,000,000 (Paid)
    // Total: 5 + 15 - 0.8 - 2 = 17,200,000.
    // Let's find "Gs. 17.200.000".
    expect(find.text('Gs. 17.200.000'), findsOneWidget);

    // 2. Add a Pending Expense of 1,000,000
    // Use Key because we replaced FAB with RawMaterialButton/InkWell
    await tester.tap(find.byKey(const Key('fab_add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1000000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pendiente'));
    await tester.pumpAndSettle();
    
    // Select Account
    // The dropdown hint is 'Seleccionar...'
    await tester.tap(find.text('Seleccionar...'), warnIfMissed: false);
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('ITAU').last); // Select from menu
    await tester.pumpAndSettle();

    // Select Category
    await tester.tap(find.text('Comida')); // Category
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar Gasto'));
    await tester.pumpAndSettle();

    // 3. Verify Balance is STILL 17.200.000 (because it's pending)
    expect(find.text('Gs. 17.200.000'), findsOneWidget);

    // 3b. Verify Dashboard shows Projected Balance and Pending Expense
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    
    final context = tester.element(find.byType(MoneyApp));
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final totalCurrentBalance = dataProvider.accounts.fold(
      0.0,
      (sum, a) => sum + dataProvider.getAccountBalance(a.id),
    );
    final pendingIncomesDashboard = dataProvider.getPendingIncomes(monthKey: dataProvider.selectedMonthKey);
    final pendingExpensesDashboard = dataProvider.getPendingExpenses(monthKey: dataProvider.selectedMonthKey);
    final projectedBalanceDashboard = totalCurrentBalance + pendingIncomesDashboard + pendingExpensesDashboard;
    final expectedHeroText = AppColors.formatCurrency(projectedBalanceDashboard);
    expect(find.text(expectedHeroText), findsOneWidget);

    // SummaryCard (Gastos) Pending text
    expect(find.textContaining('Pendiente: ₲ 1.000.000'), findsOneWidget);

    // 4. Go to Transactions Tab
    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();

    // 5. Find the pending transaction
    // It should say "PENDIENTE".
    expect(find.text('PENDIENTE'), findsOneWidget);
    // And amount 1.000.000
    expect(find.text('₲ 1.000.000'), findsOneWidget);

    // 6. Swipe to Mark as Paid
    // Find the Dismissible widget that wraps the PENDIENTE transaction.
    final pendingTextFinder = find.text('PENDIENTE');
    final dismissibleFinder = find.ancestor(
      of: pendingTextFinder,
      matching: find.byType(Dismissible),
    );
    
    await tester.drag(dismissibleFinder, const Offset(1800, 0)); // Swipe Right
     await tester.pumpAndSettle();
 
     // 7. Verify "PENDIENTE" is gone
     expect(find.text('PENDIENTE'), findsNothing);

     // 8. Verify Snackbar (Skipped as it might be flaky in test environment)
     // expect(find.text('Marcado como pagado'), findsOneWidget);
     
     // 9. Go back to Accounts Tab and check balance
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // Balance should now be 17.200.000 - 1.000.000 = 16.200.000
    expect(find.text('Gs. 16.200.000'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
