import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';

class HomeWidgetService {
  // Widget names - must match AndroidManifest and Kotlin files
  static const String _smallWidgetName = 'SmallWidgetProvider';
  static const String _mediumWidgetName = 'MediumWidgetProvider';
  static const String _largeWidgetName = 'LargeWidgetProvider';
  
  static final _formatter = NumberFormat.currency(locale: 'es_PY', symbol: 'Gs', decimalDigits: 0);

  /// Update small widget (2x1): Shows balance and quick action button
  static Future<void> updateSmallWidget(double balance) async {
    try {
      final formattedBalance = _formatter.format(balance);
      
      await HomeWidget.saveWidgetData<String>('widget_type', 'small');
      await HomeWidget.saveWidgetData<String>('balance', formattedBalance);
      await HomeWidget.saveWidgetData<String>('balance_raw', balance.toString());
      
      await HomeWidget.updateWidget(
        name: _smallWidgetName,
        androidName: _smallWidgetName,
        iOSName: _smallWidgetName,
      );
    } catch (e) {
      // Silently fail - widgets are optional
    }
  }

  /// Update medium widget (4x2): Shows top 3 categories with chart
  static Future<void> updateMediumWidget(Map<String, double> categoryExpenses, double totalExpenses) async {
    try {
      // Get top 3 categories
      final sortedCategories = categoryExpenses.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final top3 = sortedCategories.take(3).toList();
      
      // Save category data
      await HomeWidget.saveWidgetData<String>('widget_type', 'medium');
      await HomeWidget.saveWidgetData<String>('total_expenses', _formatter.format(totalExpenses));
      
      for (int i = 0; i < 3; i++) {
        if (i < top3.length) {
          await HomeWidget.saveWidgetData<String>('cat${i + 1}_name', top3[i].key);
          await HomeWidget.saveWidgetData<String>('cat${i + 1}_amount', _formatter.format(top3[i].value));
          final percentage = totalExpenses > 0 ? (top3[i].value / totalExpenses * 100).toInt() : 0;
          await HomeWidget.saveWidgetData<int>('cat${i + 1}_percent', percentage);
        } else {
          await HomeWidget.saveWidgetData<String>('cat${i + 1}_name', '');
          await HomeWidget.saveWidgetData<String>('cat${i + 1}_amount', '');
          await HomeWidget.saveWidgetData<int>('cat${i + 1}_percent', 0);
        }
      }
      
      await HomeWidget.updateWidget(
        name: _mediumWidgetName,
        androidName: _mediumWidgetName,
        iOSName: _mediumWidgetName,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Update large widget (4x4): Shows budget progress for top categories
  static Future<void> updateLargeWidget(
    List<BudgetInfo> budgets,
    double totalBalance,
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_type', 'large');
      await HomeWidget.saveWidgetData<String>('balance', _formatter.format(totalBalance));
      
      // Save up to 3 budgets
      final topBudgets = budgets.take(3).toList();
      await HomeWidget.saveWidgetData<int>('budget_count', topBudgets.length);
      
      for (int i = 0; i < 3; i++) {
        if (i < topBudgets.length) {
          final budget = topBudgets[i];
          await HomeWidget.saveWidgetData<String>('budget${i + 1}_category', budget.categoryName);
          await HomeWidget.saveWidgetData<String>('budget${i + 1}_spent', _formatter.format(budget.spent));
          await HomeWidget.saveWidgetData<String>('budget${i + 1}_limit', _formatter.format(budget.limit));
          await HomeWidget.saveWidgetData<int>('budget${i + 1}_percent', budget.percentage.toInt());
          await HomeWidget.saveWidgetData<String>('budget${i + 1}_status', budget.status);
        } else {
          await HomeWidget.saveWidgetData<String>('budget${i + 1}_category', '');
        }
      }
      
      await HomeWidget.updateWidget(
        name: _largeWidgetName,
        androidName: _largeWidgetName,
        iOSName: _largeWidgetName,
      );
    } catch (e) {
      // Silently fail
    }
  }

  /// Update all widgets with current data from DataProvider
  static Future<void> updateAllWidgets(DataProvider provider) async {
    try {
      // Calculate balance
      final totalBalance = provider.calculateTotalBalance();
      
      // Get current month data
      final monthKey = provider.selectedMonthKey;
      
      // Get category expenses
      final categoryExpenses = provider.getRealExpensesByCategory(monthKey: monthKey);
      final totalExpenses = provider.getRealExpenses(monthKey: monthKey).abs();
      
      // Get budgets
      final budgets = <BudgetInfo>[];
      for (final category in provider.categories) {
        if (category.monthlyBudget != null && category.monthlyBudget! > 0) {
          final spent = provider.getCategorySpending(category.id, monthKey);
          final percentage = (spent / category.monthlyBudget!) * 100;
          String status = 'ok';
          if (percentage >= 100) {
            status = 'exceeded';
          } else if (percentage >= 80) {
            status = 'warning';
          }
          
          budgets.add(BudgetInfo(
            categoryName: category.name,
            spent: spent,
            limit: category.monthlyBudget!,
            percentage: percentage,
            status: status,
          ));
        }
      }
      
      // Sort budgets by percentage (highest first)
      budgets.sort((a, b) => b.percentage.compareTo(a.percentage));
      
      // Convert category expenses from IDs to names
      final categoryExpensesByName = <String, double>{};
      categoryExpenses.forEach((categoryId, amount) {
        final category = provider.categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => provider.categories.first,
        );
        categoryExpensesByName[category.name] = amount;
      });
      
      // Update all widgets
      await updateSmallWidget(totalBalance);
      await updateMediumWidget(categoryExpensesByName, totalExpenses);
      await updateLargeWidget(budgets, totalBalance);
    } catch (e) {
      // Silently fail - widgets are optional
    }
  }

  /// Legacy method for backward compatibility
  static Future<void> updateBudget(double income, double expenses) async {
    final remaining = income - expenses;
    await updateSmallWidget(remaining);
  }
}

/// Helper class for budget information
class BudgetInfo {
  final String categoryName;
  final double spent;
  final double limit;
  final double percentage;
  final String status; // 'ok', 'warning', 'exceeded'

  BudgetInfo({
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.status,
  });
}
