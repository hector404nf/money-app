import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/providers/ui_provider.dart';
import 'package:money_app/models/transaction.dart';
import 'package:money_app/models/category.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_upcoming_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Upcoming Bills section filters correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
          ChangeNotifierProvider(create: (_) {
            final ui = UiProvider();
            ui.completeOnboarding();
            return ui;
          }),
        ],
        child: const MoneyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3)); // Splash
    await tester.pumpAndSettle();

    // 1. Navigate to Accounts Tab
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // 2. Setup Data
    final context = tester.element(find.byType(Scaffold).first);
    final provider = Provider.of<DataProvider>(context, listen: false);

    // Clear existing transactions to have a clean slate (optional, but safer)
    // Since we can't easily clear private list, we'll just add distinct ones and look for them.

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    // Ensure we have a category
    Category category;
    try {
      category = provider.categories.firstWhere((c) => c.name == 'UniqueBill');
    } catch (_) {
      provider.addCategory(name: 'UniqueBill', kind: CategoryKind.expense);
      category = provider.categories.firstWhere((c) => c.name == 'UniqueBill');
    }

    // A. Valid Upcoming Bill (Due Tomorrow, Pending) -> SHOULD SHOW
    provider.addTransaction(
      amount: -100000,
      categoryId: category.id,
      date: today,
      notes: 'Bill Tomorrow',
      mainType: MainType.expenses,
      accountId: 'bank',
      dueDate: tomorrow,
      status: TransactionStatus.pendiente,
    );

    // B. Paid Bill (Due Tomorrow, Paid) -> SHOULD HIDE
    provider.addTransaction(
      amount: -50000,
      categoryId: category.id,
      date: today,
      notes: 'Bill Paid',
      mainType: MainType.expenses,
      accountId: 'bank',
      dueDate: tomorrow,
      status: TransactionStatus.pagado,
    );

    // C. Overdue Bill (Due Yesterday, Pending) -> SHOULD HIDE (Current Logic)
    provider.addTransaction(
      amount: -20000,
      categoryId: category.id,
      date: today,
      notes: 'Bill Overdue',
      mainType: MainType.expenses,
      accountId: 'bank',
      dueDate: yesterday,
      status: TransactionStatus.pendiente,
    );

    // D. No Due Date (Pending) -> SHOULD HIDE
    provider.addTransaction(
      amount: -30000,
      categoryId: category.id,
      date: today,
      notes: 'Bill NoDate',
      mainType: MainType.expenses,
      accountId: 'bank',
      status: TransactionStatus.pendiente,
    );

    await tester.pumpAndSettle();

    // 3. Verify Visibility
    
    // Scroll down to reveal the section (it's at the bottom)
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // Check Header exists
    expect(find.text('Cuentas por pagar'), findsOneWidget);

    // Check Valid Bill exists (It shows Category Name, not Notes)
    expect(find.text('UniqueBill'), findsOneWidget);

    // Check count: Should be 1 (because only 1 valid bill)
    // If others were shown, we would find 'UniqueBill' multiple times or we need to check other attributes.
    // Since we used same category for all, if 4 were shown, we'd find 4 'UniqueBill' widgets.
    // But we expect only 1.
    expect(find.text('UniqueBill'), findsOneWidget);
    
    // To be absolutely sure, we can check the subtitle of the found widget or count.
    // But findsOneWidget ensures exactly one.
    
    // Also check "1 en camino" text
    expect(find.text('1 en camino'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });
}
