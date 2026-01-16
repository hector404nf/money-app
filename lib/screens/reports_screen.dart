import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/ui_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DataProvider>(context);
    final selectedMonthKey = provider.selectedMonthKey;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reportes',
                style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
              ),
              Text(
                'Análisis de tus finanzas',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 20),
                        SizedBox(width: 8),
                        Text('Resumen'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Categorías'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedMonthKey,
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color, size: 20),
                      ),
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      isDense: true,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Todo el historial',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        ...provider.availableMonthKeys.map(
                          (key) => DropdownMenuItem<String?>(
                            value: key,
                            child: Text(
                              key,
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => provider.setSelectedMonthKey(value),
                      dropdownColor: theme.cardTheme.color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  _SummaryTab(),
                  _CategoriesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DataProvider>(context);
    final ui = Provider.of<UiProvider>(context);
    final monthKey = provider.selectedMonthKey;
    final paydayDay = ui.paydayDay;

    final income = provider.getIncomes(monthKey: monthKey);
    final expense = provider.getRealExpenses(monthKey: monthKey);
    final savings = income + expense; 
    final savingsRate = income > 0 ? (savings / income) : 0.0;
    final savingsPercentage = (savingsRate * 100).clamp(0, 100).toInt();

    String status = 'Crítico';
    Color statusColor = Colors.red;
    if (savingsRate >= 0.5) {
      status = 'Excelente';
      statusColor = Colors.green;
    } else if (savingsRate >= 0.2) {
      status = 'Bueno';
      statusColor = Colors.blue;
    } else if (savingsRate > 0) {
      status = 'Regular';
      statusColor = Colors.orange;
    }

    double dailyBudget = 0;
    double dailyAverage = 0;
    int daysLeftInCycle = 0;

    if (paydayDay != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int targetMonth = today.day < paydayDay ? today.month : today.month + 1;
      int targetYear = today.year;
      if (targetMonth > 12) {
        targetMonth = 1;
        targetYear += 1;
      }
      final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final safeDayNext = paydayDay.clamp(1, lastDayOfTargetMonth);
      final nextPayday = DateTime(targetYear, targetMonth, safeDayNext);

      int lastMonth = today.day >= paydayDay ? today.month : today.month - 1;
      int lastYear = today.year;
      if (lastMonth <= 0) {
        lastMonth = 12;
        lastYear -= 1;
      }
      final lastDayOfLastMonth = DateTime(lastYear, lastMonth + 1, 0).day;
      final safeDayLast = paydayDay.clamp(1, lastDayOfLastMonth);
      final lastPayday = DateTime(lastYear, lastMonth, safeDayLast);

      final daysElapsed = today.difference(lastPayday).inDays + 1;
      final safeElapsed = daysElapsed > 0 ? daysElapsed : 1;

      final spentCycle = provider.getRealExpensesInRange(lastPayday, today).abs();
      dailyAverage = spentCycle / safeElapsed;

      final pendingIncomes = provider.getPendingIncomes(monthKey: monthKey);
      final pendingExpenses = provider.getPendingExpenses(monthKey: monthKey);
      final totalCurrentBalance = provider.accounts.fold(0.0, (sum, a) => sum + provider.getAccountBalance(a.id));
      final projectedBalance = totalCurrentBalance + pendingIncomes + pendingExpenses;

      final daysLeft = nextPayday.difference(today).inDays;
      daysLeftInCycle = daysLeft > 0 ? daysLeft : 1;
      dailyBudget = projectedBalance > 0 ? projectedBalance / daysLeftInCycle : 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Tarjeta de Tasa de Ahorro
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasa de ahorro',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$savingsPercentage%',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: savingsRate.clamp(0.0, 1.0),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    color: const Color(0xFF00695C),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ingresos y Gastos
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: 'Ingresos',
                  amount: income,
                  color: AppColors.income,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard(
                  label: 'Gastos',
                  amount: expense,
                  color: AppColors.expense,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ahorro del mes
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahorro del mes',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${savings >= 0 ? '+' : ''}${AppColors.formatCurrency(savings)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: savings >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
          if (paydayDay != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Control de gasto diario',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$daysLeftInCycle días restantes',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Promedio gastado por día',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        AppColors.formatCurrency(dailyAverage),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Presupuesto diario recomendado',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        AppColors.formatCurrency(dailyBudget),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppColors.formatCurrency(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<DataProvider>(context);
    final monthKey = provider.selectedMonthKey;

    // Filter transactions by month and expense type
    final transactions = provider.transactions.where((t) {
      final matchesMonth = monthKey == null || t.monthKey == monthKey;
      return matchesMonth && t.amount < 0; // Only expenses
    }).toList();

    final totalExpense = transactions.fold(0.0, (sum, t) => sum + t.amount.abs());

    // Group by category
    final categoryTotals = <String, double>{};
    for (var t in transactions) {
      categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amount.abs();
    }

    // Convert to list and sort
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay gastos registrados',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final categoryId = entry.key;
        final amount = entry.value;
        final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;
        final percentageInt = (percentage * 100).toInt();

        final category = provider.categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => Category(id: 'unknown', name: 'Desconocido', kind: CategoryKind.expense),
        );

        final budget = category.monthlyBudget;
        final hasBudget = budget != null && budget > 0;
        
        String subtext;
        Color progressColor;
        double progressValue;
        Widget? extraInfo;

        if (hasBudget) {
          final budgetPercent = amount / budget!;
          final budgetPercentInt = (budgetPercent * 100).toInt();
          
          if (budgetPercent >= 1.0) {
            progressColor = Colors.red;
          } else if (budgetPercent >= 0.8) {
            progressColor = Colors.orange;
          } else {
            progressColor = Colors.teal;
          }
          
          progressValue = budgetPercent.clamp(0.0, 1.0);
          subtext = '${AppColors.formatCurrency(amount)} de ${AppColors.formatCurrency(budget)} ($budgetPercentInt%)';
          
          if (budgetPercent > 1.0) {
            extraInfo = Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Excedido por ${AppColors.formatCurrency(amount - budget)}',
                style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            );
          }
        } else {
          subtext = '$percentageInt% del total';
          progressColor = Colors.blueAccent;
          progressValue = percentage;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasBudget ? progressColor.withOpacity(0.1) : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconHelper.getIconByName(category.iconName ?? 'category'),
                      color: hasBudget ? progressColor : Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          subtext,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasBudget) // Only show amount on right if not showing budget details inline (or keep it?)
                  Text(
                    AppColors.formatCurrency(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  color: progressColor,
                  minHeight: 8, // Slightly thicker for budget visibility
                ),
              ),
              if (extraInfo != null) extraInfo,
            ],
          ),
        );
      },
    );
  }
}
