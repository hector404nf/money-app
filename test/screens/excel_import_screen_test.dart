import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/screens/excel_import_screen.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use a temp dir for Hive
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_excel_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveTestDir.exists()) {
        await hiveTestDir.delete(recursive: true);
    }
  });

  testWidgets('ExcelImportScreen renders initial state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
        ],
        child: MaterialApp(
          home: const ExcelImportScreen(),
        ),
      ),
    );

    // Allow any async initialization to settle
    await tester.pumpAndSettle();

    expect(find.text('Importar Excel'), findsOneWidget);
    expect(find.text('Seleccionar Archivo Excel'), findsOneWidget);
    // Year dropdown default
    expect(find.text('${DateTime.now().year}'), findsOneWidget);
  });
}
