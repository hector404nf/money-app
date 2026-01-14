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
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_hive_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Add Transaction screen supports transfer mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify SegmentedButton has 'Gasto' selected by default
    expect(find.text('Gasto'), findsOneWidget);
    
    // Tap on 'Transf.' segment
    await tester.tap(find.text('Transf.'));
    await tester.pumpAndSettle();

    // Verify transfer fields appear
    expect(find.text('Desde'), findsOneWidget);
    expect(find.text('Hacia'), findsOneWidget);
    expect(find.text('Guardar Transferencia'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Account management flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 3000);
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

    // 1. Ir a la pestaña Cuentas
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    // 2. Verificar que estamos en Cuentas y hay botón de agregar
    expect(find.text('Cuentas'), findsWidgets); // Header and Nav item
    
    // Ensure we are at the top of the list
    // await tester.drag(find.byType(ListView), const Offset(0, 500));
    // await tester.pump();
    
    expect(find.byKey(const Key('add_account_button')), findsOneWidget);

    // 3. Crear nueva cuenta
    await tester.tap(find.byKey(const Key('add_account_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nueva Cuenta'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Ahorro Secreto');
    await tester.enterText(find.byType(TextFormField).last, '500000');
    
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pumpAndSettle();

    // 4. Verificar que aparece en la lista
    expect(find.text('Ahorro Secreto'), findsOneWidget);
    expect(find.text('Gs. 500.000'), findsOneWidget);

    // 5. Editar la cuenta
    await tester.tap(find.text('Ahorro Secreto'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Cuenta'), findsOneWidget);
    // Cambiar nombre
    await tester.enterText(find.byType(TextFormField).first, 'Ahorro Visible');
    await tester.tap(find.text('Guardar Cambios'));
    await tester.pumpAndSettle();

    // 6. Verificar cambio
    expect(find.text('Ahorro Visible'), findsOneWidget);
    expect(find.text('Ahorro Secreto'), findsNothing);

    addTearDown(tester.view.resetPhysicalSize);
  });

  test('DataProvider addTransfer creates two movements and keeps real totals', () {
    final provider = DataProvider();

    final fromBefore = provider.getAccountBalance('1');
    final toBefore = provider.getAccountBalance('3');
    final incomesBefore = provider.getIncomes();
    final realExpensesBefore = provider.getRealExpenses();

    provider.addTransfer(
      amount: 12345,
      fromAccountId: '1',
      toAccountId: '3',
      date: DateTime(2026, 1, 20),
      notes: 'Prueba',
    );

    final fromAfter = provider.getAccountBalance('1');
    final toAfter = provider.getAccountBalance('3');
    final incomesAfter = provider.getIncomes();
    final realExpensesAfter = provider.getRealExpenses();

    expect(fromAfter, fromBefore - 12345);
    expect(toAfter, toBefore + 12345);
    expect(incomesAfter, incomesBefore);
    expect(realExpensesAfter, realExpensesBefore);
  });
}
