import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/providers/ui_provider.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_add_tx_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Add Transaction UI Logic: Status and Due Date visibility', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 3000);
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
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Open Add Transaction Screen
    // Use Key because we replaced FAB with RawMaterialButton/InkWell
    await tester.tap(find.byKey(const Key('fab_add')));
    await tester.pumpAndSettle();

    // 1. Default state (Expense)
    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Pagado'), findsOneWidget);
    
    // Check 'Pagado' is selected (you might need to check color or decoration, but simple text existence is a good start)
    // Actually, all options are visible text-wise.
    
    // Check Due Date is NOT visible
    expect(find.text('Fecha de Vencimiento'), findsNothing);

    // 2. Select 'Pendiente'
    await tester.tap(find.text('Pendiente'));
    await tester.pumpAndSettle();

    // Check Due Date IS visible
    expect(find.text('Fecha de Vencimiento'), findsOneWidget);
    expect(find.text('Seleccionar fecha...'), findsOneWidget); // Default text when null

    // 3. Select 'Programado'
    await tester.tap(find.text('Programado'));
    await tester.pumpAndSettle();
    
    // Check Due Date IS visible
    expect(find.text('Fecha de Vencimiento'), findsOneWidget);

    // 4. Select 'Pagado' again
    await tester.tap(find.text('Pagado'));
    await tester.pumpAndSettle();
    
    // Check Due Date is NOT visible
    expect(find.text('Fecha de Vencimiento'), findsNothing);

    // 5. Switch to Transfer
    await tester.tap(find.text('Transf.'));
    await tester.pumpAndSettle();

    // Check Status is NOT visible
    expect(find.text('Estado'), findsNothing);
    expect(find.text('Pendiente'), findsNothing); // Should be gone from UI

    addTearDown(tester.view.resetPhysicalSize);
  });
}
