import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';
import 'manage_category_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Presupuestos Mensuales', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.iconTheme.color),
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories
              .where((c) => c.kind == CategoryKind.expense)
              .toList();
          
          // Sort: Categories with budget first, then by name
          categories.sort((a, b) {
            if (a.monthlyBudget != null && b.monthlyBudget == null) return -1;
            if (a.monthlyBudget == null && b.monthlyBudget != null) return 1;
            return a.name.compareTo(b.name);
          });

          if (categories.isEmpty) {
            return const Center(child: Text('No hay categorías de gastos'));
          }

          final monthKey = provider.selectedMonthKey;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final spent = provider.getCategorySpending(category.id, monthKey);
              final budget = category.monthlyBudget;
              
              return _BudgetCard(
                category: category,
                spent: spent,
                budget: budget,
                onTap: () => _showBudgetDialog(context, category, provider),
              );
            },
          );
        },
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, Category category, DataProvider provider) {
    final controller = TextEditingController(
      text: category.monthlyBudget != null 
          ? category.monthlyBudget!.toStringAsFixed(0) 
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Presupuesto para ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto Mensual (Gs)',
                hintText: '0 para eliminar',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', ''));
              if (amount != null) {
                provider.editCategory(
                  id: category.id,
                  name: category.name,
                  monthlyBudget: amount > 0 ? amount : null,
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Category category;
  final double spent;
  final double? budget;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.category,
    required this.spent,
    this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Icon
    IconData iconData;
    if (category.iconName != null) {
      iconData = IconHelper.getIconByName(category.iconName!);
    } else {
      iconData = IconHelper.getCategoryIcon(category.name);
    }

    final hasBudget = budget != null && budget! > 0;
    final progress = hasBudget ? (spent / budget!).clamp(0.0, 1.0) : 0.0;
    
    Color progressColor = AppColors.income; // Green
    if (hasBudget) {
      final percentage = spent / budget!;
      if (percentage >= 1.0) {
        progressColor = AppColors.expense; // Red
      } else if (percentage >= 0.8) {
        progressColor = Colors.orange; // Warning
      }
    }

    return Card(
      elevation: 0,
      color: theme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasBudget ? progressColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: hasBudget ? progressColor : Colors.grey,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (hasBudget)
                          Text(
                            '${(spent / budget! * 100).toStringAsFixed(0)}% del presupuesto',
                            style: TextStyle(
                              color: progressColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const Text(
                            'Sin presupuesto asignado',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasBudget)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppColors.formatCurrency(spent),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'de ${AppColors.formatCurrency(budget!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (hasBudget) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
