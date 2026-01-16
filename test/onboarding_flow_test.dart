import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/providers/ui_provider.dart';
import 'package:money_app/screens/onboarding_screen.dart';
import 'package:money_app/screens/home_screen.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_onboarding_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Fresh install shows Onboarding', (WidgetTester tester) async {
    // 1. Start App with seenOnboarding = false (default)
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
          ChangeNotifierProvider(create: (_) => UiProvider()), // Default is false
        ],
        child: const MoneyApp(),
      ),
    );

    // 2. Wait for Splash
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Verify Onboarding Screen
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    // 4. Complete Onboarding
    // The Onboarding screen has 4 pages. We need to tap the "Next" button 4 times.
    // The button contains an Icon (arrow_forward or check).
    
    final buttonFinder = find.byType(ElevatedButton);
    
    // Page 1 -> 2
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    
    // Page 2 -> 3
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    
    // Page 3 -> 4
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    
    // Page 4 -> Finish
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // 5. Verify Home Screen
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Returning user skips Onboarding', (WidgetTester tester) async {
    // 1. Start App with seenOnboarding = true
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DataProvider()),
          ChangeNotifierProvider(create: (_) {
            final ui = UiProvider();
            ui.completeOnboarding(); // Mark as seen
            return ui;
          }),
        ],
        child: const MoneyApp(),
      ),
    );

    // 2. Wait for Splash
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Verify Home Screen directly
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });
}
