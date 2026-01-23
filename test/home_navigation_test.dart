import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/providers/ui_provider.dart';
import 'package:money_app/screens/ai_input_screen.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_nav_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Long press on FAB navigates to AiInputScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
    await tester.pumpAndSettle();

    // Verify FAB is present
    // Note: In HomeScreen we replaced FAB with a Material widget inside SizedBox inside floatingActionButton slot.
    // We can find it by Key.
    final fabFinder = find.byKey(const Key('fab_add'));
    expect(fabFinder, findsOneWidget);

    // Perform Long Press
    await tester.longPress(fabFinder);
    await tester.pumpAndSettle();

    // Verify navigation to AiInputScreen
    expect(find.byType(AiInputScreen), findsOneWidget);
    expect(find.text('Asistente IA (Beta)'), findsOneWidget);
    
    addTearDown(tester.view.resetPhysicalSize);
  });
}
