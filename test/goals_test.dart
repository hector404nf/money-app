import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/screens/add_goal_screen.dart';
import 'package:money_app/screens/add_transaction_screen.dart';
import 'package:money_app/widgets/transaction_tile.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_goals_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Create a new Goal and verify it appears in Accounts Tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
        ],
        child: const MoneyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigate to Accounts Tab
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // 2. Tap on "Nueva Meta" (text button) or "Add" icon button
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final newGoalFinder = find.byKey(const Key('add_goal_text_button'));
    if (newGoalFinder.evaluate().isNotEmpty) {
      await tester.ensureVisible(newGoalFinder);
      await tester.tap(newGoalFinder);
    } else {
      final iconFinder = find.byKey(const Key('add_goal_icon_button'));
      await tester.ensureVisible(iconFinder);
      await tester.tap(iconFinder);
    }
    await tester.pumpAndSettle();

    expect(find.byType(AddGoalScreen), findsOneWidget, reason: 'AddGoalScreen not pushed');

    // 3. Fill the Add Goal form
    await tester.enterText(find.byType(TextFormField).at(0), 'Mi Primer Millón');
    await tester.enterText(find.byType(TextFormField).at(1), '1000000');
    
    // Select Icon (e.g., flight - index 3 in the list)
    await tester.tap(find.byIcon(Icons.flight));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Crear Meta'));
    await tester.pumpAndSettle();

    // 4. Verify the new goal is displayed
    expect(find.text('Mi Primer Millón'), findsOneWidget);
    expect(find.text('de Gs. 1.000.000'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // 5. Test Goal Details and Add Funds
    await tester.dragUntilVisible(
      find.text('Mi Primer Millón'),
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mi Primer Millón'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar Fondos'), findsOneWidget);

    // Add Funds
    await tester.tap(find.text('Agregar Fondos'));
    await tester.pumpAndSettle();

    // Verify AddTransactionScreen is open
    expect(find.byType(AddTransactionScreen), findsOneWidget);
    
    // Select Source Account (From)
    final dropdowns = find.byType(DropdownButton<String>);
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Efectivo').last);
    await tester.pumpAndSettle();

    // Enter Amount
    await tester.enterText(find.byType(TextFormField).at(0), '500000');
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Guardar Transferencia'));
    await tester.pumpAndSettle();
    
    // Verify Goal Balance Updated
    // We should be back in AccountsTab
    
    // Verify updated progress in the card
    await tester.dragUntilVisible(
      find.text('Mi Primer Millón'),
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    // Check if the card shows the updated amount: 500.000
    expect(find.text('Gs. 500.000'), findsOneWidget);
    
    // Check if progress updated
    // 500,000 / 1,000,000 = 50%
    expect(find.text('50%'), findsOneWidget);

    // 5b. Verify Transaction Details (Fix for "Cuenta desconocida")
    // Go to Transactions Tab
    await tester.tap(find.byIcon(Icons.list_alt_outlined));
    await tester.pumpAndSettle();
    
    // Find tiles with amount 500.000
    // The format is '₲ 500.000'
    final amountFinder = find.text('₲ 500.000');
    expect(amountFinder, findsAtLeastNWidgets(1), reason: 'Should find at least one transaction with amount 500.000');
    
    bool foundGoalTransaction = false;
    
    // Iterate over found widgets
    final elements = amountFinder.evaluate().toList();
    for (var element in elements) {
       await tester.tap(find.byWidget(element.widget));
       await tester.pumpAndSettle();
       
       if (find.text('Mi Primer Millón').evaluate().isNotEmpty) {
         foundGoalTransaction = true;
         // Verify "Cuenta desconocida" is NOT present
         expect(find.text('Cuenta desconocida'), findsNothing);
         // Go back
         await tester.tap(find.byIcon(Icons.arrow_back));
         await tester.pumpAndSettle();
         break;
       }
       
       // Go back if not the one we are looking for
       await tester.tap(find.byIcon(Icons.arrow_back));
       await tester.pumpAndSettle();
    }
    
    expect(foundGoalTransaction, isTrue, reason: 'Could not find transaction linked to Goal');

    // Return to Accounts Tab for deletion
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // Scroll to find the goal card again
    await tester.dragUntilVisible(
      find.text('Mi Primer Millón'),
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    // 6. Test Delete Goal
    await tester.tap(find.text('Mi Primer Millón'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar')); // In bottom sheet
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar')); // In confirmation dialog
    await tester.pumpAndSettle();

    expect(find.text('Mi Primer Millón'), findsNothing);
  });
}
