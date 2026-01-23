import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  // Must match the class name in AndroidManifest and Kotlin file
  static const String _androidWidgetName = 'HomeWidgetProvider';

  static Future<void> updateBudget(double income, double expenses) async {
    final remaining = income - expenses;
    // Format: Gs. 1.500.000
    final formatter = NumberFormat.currency(locale: 'es_PY', symbol: 'Gs');
    final formattedBudget = formatter.format(remaining);

    // Save data to SharedPreferences (Android) / UserDefaults (iOS)
    await HomeWidget.saveWidgetData<String>('remaining_budget', formattedBudget);
    
    // Trigger update
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
