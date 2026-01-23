import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';
import 'add_transaction_screen.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter recurring transactions (Templates)
    // Only those that are recurring AND are parent templates (parentRecurringId == null)
    // And usually expenses
    final subscriptions = provider.transactions.where((t) {
      return t.isRecurring && 
             t.parentRecurringId == null && 
             t.mainType == MainType.expenses &&
             t.frequency != null;
    }).toList();

    // Calculate total monthly cost
    double totalMonthly = 0;
    for (var sub in subscriptions) {
      if (sub.frequency == RecurringFrequency.monthly) {
        totalMonthly += sub.amount.abs();
      } else if (sub.frequency == RecurringFrequency.weekly) {
        totalMonthly += sub.amount.abs() * 4; // Approx
      } else if (sub.frequency == RecurringFrequency.yearly) {
        totalMonthly += sub.amount.abs() / 12;
      } else if (sub.frequency == RecurringFrequency.daily) {
        totalMonthly += sub.amount.abs() * 30;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripciones'),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(
                initialFlow: TransactionFlow.expense,
                // We can't easily preset recurring=true via constructor yet, 
                // but user can toggle it. Or we could modify AddTransactionScreen.
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Costo Mensual Estimado',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppColors.formatCurrency(totalMonthly),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${subscriptions.length} suscripciones activas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 64,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes suscripciones',
                          style: TextStyle(
                            color: theme.disabledColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Añade tus gastos recurrentes aquí',
                          style: TextStyle(
                            color: theme.disabledColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      final category = provider.categories.firstWhere(
                        (c) => c.id == sub.categoryId,
                        orElse: () => Category(
                          id: 'unknown',
                          name: 'Desconocido',
                          kind: CategoryKind.expense,
                        ),
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.expense.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              IconHelper.getIconByName(category.iconName ?? 'category'),
                              color: AppColors.expense,
                            ),
                          ),
                          title: Text(
                            sub.notes?.isNotEmpty == true ? sub.notes! : category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _getFrequencyText(sub.frequency),
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 13,
                                ),
                              ),
                              if (sub.dueDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Próximo cobro: ${DateFormat('dd/MM/yyyy').format(sub.dueDate!)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.orangeAccent : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppColors.formatCurrency(sub.amount.abs()),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                             // Edit flow?
                             // For now, simple alert or navigation to edit
                             // Ideally pass existing transaction to AddTransactionScreen
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(RecurringFrequency? frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Diario';
      case RecurringFrequency.weekly:
        return 'Semanal';
      case RecurringFrequency.monthly:
        return 'Mensual';
      case RecurringFrequency.yearly:
        return 'Anual';
      default:
        return 'Recurrente';
    }
  }
}
