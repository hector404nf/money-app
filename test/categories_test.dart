import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:money_app/main.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:money_app/screens/categories_screen.dart';
import 'package:money_app/screens/manage_category_screen.dart';
import 'package:money_app/utils/icon_helper.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_categories_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  testWidgets('Manage Categories: Add, Edit, Delete', (WidgetTester tester) async {
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

    // 1. Navigate to Settings -> Categories
    // Settings is the 4th tab (index 3)
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();

    expect(find.byType(CategoriesScreen), findsOneWidget);

    // 2. Add New Category
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(ManageCategoryScreen), findsOneWidget);

    // Enter Name
    await tester.enterText(find.byType(TextFormField), 'Gaming');
    
    // Select Icon (e.g., sports_esports)
    // We need to scroll to find it in the grid if it's not visible, but for now let's try to tap it.
    // The grid has many items. 'sports_esports' is in the list.
    // Let's scroll the GridView.
    
    // Find the GridView
    final gridFinder = find.byType(GridView);
    
    // Scroll until we find the icon
    // Note: Icons are rendered as Icon(IconData). We can find by Icon.
    final iconData = IconHelper.getIconByName('sports_esports');
    
    await tester.dragUntilVisible(
      find.byIcon(iconData),
      gridFinder,
      const Offset(0, -500),
    );
    await tester.tap(find.byIcon(iconData));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Crear Categoría'));
    await tester.pumpAndSettle();

    // 3. Verify it appears
    expect(find.text('Gaming'), findsOneWidget);
    // Note: It defaults to Expense tab, which is what we want.

    // 4. Edit Category
    await tester.tap(find.text('Gaming'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Categoría'), findsOneWidget);

    // Change Name
    await tester.enterText(find.byType(TextFormField), 'Juegos');
    
    // Change Icon to 'movie'
    final movieIconData = IconHelper.getIconByName('movie');
     await tester.dragUntilVisible(
      find.byIcon(movieIconData),
      gridFinder,
      const Offset(0, -500),
    );
    await tester.tap(find.byIcon(movieIconData));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Guardar Cambios'));
    await tester.pumpAndSettle();

    // 5. Verify Update
    expect(find.text('Juegos'), findsOneWidget);
    expect(find.text('Gaming'), findsNothing);

    // 6. Delete Category
    await tester.tap(find.text('Juegos'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Confirm Dialog
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // 7. Verify Deletion
    expect(find.text('Juegos'), findsNothing);
  });
}
