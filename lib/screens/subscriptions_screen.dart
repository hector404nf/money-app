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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthKey = provider.selectedMonthKey ?? '${today.year}-${today.month.toString().padLeft(2, '0')}';

    // Filter recurring transactions (Templates)
    // Only those that are recurring AND are parent templates (parentRecurringId == null)
    // And usually expenses
    final subscriptions = provider.transactions.where((t) {
      return t.isRecurring && 
             t.parentRecurringId == null && 
             t.mainType == MainType.expenses &&
             t.frequency != null;
    }).toList();

    subscriptions.sort((a, b) {
      final aNext = _getNextChargeDate(provider.transactions, a, today);
      final bNext = _getNextChargeDate(provider.transactions, b, today);

      if (aNext == null && bNext == null) return 0;
      if (aNext == null) return 1;
      if (bNext == null) return -1;
      return aNext.compareTo(bNext);
    });

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

    final incomes = provider.getIncomes(monthKey: monthKey);
    final percentOfIncomes = incomes > 0 ? (totalMonthly / incomes) * 100 : null;

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
                initialStatus: TransactionStatus.programado,
                initialRecurringFrequency: RecurringFrequency.monthly,
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
                if (percentOfIncomes != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '≈ ${percentOfIncomes.toStringAsFixed(0)}% de tus ingresos este mes',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                      final nextTx = _getNextChargeTransaction(provider.transactions, sub, today);
                      final nextCharge = nextTx == null ? null : (nextTx.dueDate ?? nextTx.date);
                      final lastPaid = _getLastPaidDate(provider.transactions, sub);
                      final lastPaidDay = lastPaid == null ? null : DateTime(lastPaid.year, lastPaid.month, lastPaid.day);
                      final isInactive = lastPaidDay != null && today.difference(lastPaidDay).inDays > 60;
                      final daysRemaining = nextCharge == null
                          ? null
                          : DateTime(nextCharge.year, nextCharge.month, nextCharge.day).difference(today).inDays;
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
                              if (isInactive)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Inactiva (sin pagos hace 60+ días)',
                                    style: TextStyle(
                                      color: isDark ? Colors.redAccent : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (nextCharge != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Próximo cobro: ${DateFormat('dd/MM/yyyy').format(nextCharge)}',
                                    style: TextStyle(
                                      color: isDark ? Colors.orangeAccent : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (daysRemaining != null && daysRemaining >= 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    daysRemaining == 0 ? 'Vence hoy' : 'Faltan $daysRemaining días',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (lastPaid != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Último pago: ${DateFormat('dd/MM/yyyy').format(lastPaid)}',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(height: 4),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'mark_paid') {
                                    if (nextTx == null) return;
                                    provider.updateTransactionStatus(nextTx.id, TransactionStatus.pagado);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Marcado como pagado')),
                                      );
                                    }
                                    return;
                                  }

                                  if (value == 'delete') {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Eliminar suscripción'),
                                        content: const Text('Se eliminarán los cobros futuros de esta suscripción.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed != true) return;
                                    provider.deleteRecurringSeries(sub.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Suscripción eliminada')),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (nextTx != null)
                                    const PopupMenuItem<String>(
                                      value: 'mark_paid',
                                      child: Text('Marcar próximo como pagado'),
                                    ),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  DateTime? _getNextChargeDate(List<Transaction> all, Transaction template, DateTime today) {
    final related = all.where((t) => t.id == template.id || t.parentRecurringId == template.id).where((t) => t.status != TransactionStatus.pagado).toList();
    if (related.isEmpty) return null;

    related.sort((a, b) {
      final aDate = a.dueDate ?? a.date;
      final bDate = b.dueDate ?? b.date;
      return aDate.compareTo(bDate);
    });

    for (final tx in related) {
      final d = tx.dueDate ?? tx.date;
      final dayOnly = DateTime(d.year, d.month, d.day);
      if (!dayOnly.isBefore(today)) return d;
    }

    return related.first.dueDate ?? related.first.date;
  }

  Transaction? _getNextChargeTransaction(List<Transaction> all, Transaction template, DateTime today) {
    final related = all
        .where((t) => t.id == template.id || t.parentRecurringId == template.id)
        .where((t) => t.status != TransactionStatus.pagado)
        .toList();
    if (related.isEmpty) return null;

    related.sort((a, b) {
      final aDate = a.dueDate ?? a.date;
      final bDate = b.dueDate ?? b.date;
      return aDate.compareTo(bDate);
    });

    for (final tx in related) {
      final d = tx.dueDate ?? tx.date;
      final dayOnly = DateTime(d.year, d.month, d.day);
      if (!dayOnly.isBefore(today)) return tx;
    }

    return related.first;
  }

  DateTime? _getLastPaidDate(List<Transaction> all, Transaction template) {
    final related = all.where((t) => t.id == template.id || t.parentRecurringId == template.id).where((t) => t.status == TransactionStatus.pagado).toList();
    if (related.isEmpty) return null;
    related.sort((a, b) => b.date.compareTo(a.date));
    return related.first.date;
  }
}
