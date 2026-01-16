import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/ui_provider.dart';
import '../models/category.dart';
import '../widgets/hero_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/transaction_tile.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';
import 'sync_screen.dart';
import 'reports_screen.dart';
import '../services/update_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // Verificar actualizaciones al iniciar el dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final ui = Provider.of<UiProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedMonthKey = provider.selectedMonthKey;
    final incomes = provider.getIncomes(monthKey: selectedMonthKey);
    final realExpenses = provider.getRealExpenses(monthKey: selectedMonthKey);

    final pendingIncomes = provider.getPendingIncomes(monthKey: selectedMonthKey);
    final pendingExpenses = provider.getPendingExpenses(monthKey: selectedMonthKey);

    final currentBalance = incomes + realExpenses; // Paid only
    final projectedBalance = currentBalance + pendingIncomes + pendingExpenses;
    
    // Obtener transacciones recientes (filtradas por mes si aplica)
    final recentTransactions = provider.transactions.where((t) {
      if (selectedMonthKey == null) return true;
      return t.monthKey == selectedMonthKey;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola,',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Resumen Financiero',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.headlineSmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
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
            ],
            ),
            
            const SizedBox(height: 24),
            
            HeroCard(amount: projectedBalance),
            
            const SizedBox(height: 24),

            Builder(
              builder: (context) {
                final paydayDay = ui.paydayDay;
                if (paydayDay == null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? theme.cardTheme.color : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.blueGrey.shade700 : Colors.blue.shade100,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tips_and_updates,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Es bueno saber',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Configura tu día de cobro en Ajustes para ver cuántos días faltan y cuánto podés gastar por día.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SettingsTab()),
                                    );
                                  },
                                  child: const Text('Configurar día de cobro'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                int targetMonth = today.day < paydayDay ? today.month : today.month + 1;
                int targetYear = today.year;
                if (targetMonth > 12) {
                  targetMonth = 1;
                  targetYear += 1;
                }
                final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
                final safeDay = paydayDay.clamp(1, lastDayOfTargetMonth);
                final nextPayday = DateTime(targetYear, targetMonth, safeDay);
                final daysLeft = nextPayday.difference(today).inDays;
                final effectiveDays = daysLeft > 0 ? daysLeft : 1;

                final dailyAmount = projectedBalance > 0 ? projectedBalance / effectiveDays : 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardTheme.color : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.blueGrey.shade700 : Colors.blue.shade100,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Es bueno saber',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Con tu saldo actual, podrías gastar este monto por día hasta tu próximo cobro.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DÍAS HASTA COBRAR',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$effectiveDays',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PARA EL GASTO DIARIO',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '₲ ${dailyAmount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]}.')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Budget Alerts
            Builder(
              builder: (context) {
                if (selectedMonthKey == null) return const SizedBox.shrink();
                
                int alertCount = 0;
                int exceededCount = 0;

                for (var cat in provider.categories) {
                  if (cat.monthlyBudget != null && cat.monthlyBudget! > 0) {
                    final spent = provider.getCategorySpending(cat.id, selectedMonthKey);
                    final ratio = spent / cat.monthlyBudget!;
                    if (ratio >= 1.0) {
                      exceededCount++;
                    } else if (ratio >= 0.8) {
                      alertCount++;
                    }
                  }
                }

                if (alertCount == 0 && exceededCount == 0) return const SizedBox.shrink();

                return GestureDetector(
                  onTap: () {
                     Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                       color: exceededCount > 0 ? Colors.red.shade50 : Colors.amber.shade50,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(
                         color: exceededCount > 0 ? Colors.red.shade200 : Colors.amber.shade200
                       ),
                    ),
                    child: Row(
                       children: [
                         Icon(
                           exceededCount > 0 ? Icons.error_outline : Icons.warning_amber_rounded, 
                           color: exceededCount > 0 ? Colors.red[800] : Colors.orange[800]
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Text(
                             exceededCount > 0 
                               ? '¡$exceededCount categorías excedieron su presupuesto!' 
                               : '$alertCount categorías cerca del límite.',
                             style: TextStyle(
                               color: exceededCount > 0 ? Colors.red[900] : Colors.orange[900], 
                               fontWeight: FontWeight.w600
                             ),
                           ),
                         ),
                         Icon(
                           Icons.chevron_right, 
                           color: exceededCount > 0 ? Colors.red[800] : Colors.orange[800]
                         ),
                       ],
                    ),
                  ),
                );
              }
            ),

            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              QuickActionButton(
                icon: Icons.add,
                label: 'Nuevo',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                ),
              ),
              QuickActionButton(
                icon: Icons.sync,
                label: 'Sincronizar',
                color: AppColors.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SyncScreen()),
                ),
              ),
              QuickActionButton(
                icon: Icons.analytics_outlined,
                label: 'Reportes',
                color: const Color(0xFF1976D2), // Azul Transferencia
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
              ),
            ],
            ),
            
            const SizedBox(height: 32),
            
            Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'Ingresos',
                  amount: incomes,
                  pendingAmount: pendingIncomes,
                  icon: Icons.trending_up,
                  color: AppColors.income,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SummaryCard(
                  title: 'Gastos',
                  amount: realExpenses,
                  pendingAmount: pendingExpenses,
                  icon: Icons.trending_down,
                  color: AppColors.expense,
                ),
              ),
            ],
            ),

            const SizedBox(height: 32),
            
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Últimos movimientos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Cambiar a la tab de movimientos (índice 2)
                  // Esto requiere acceso al estado del padre o usar un provider para la navegación.
                  // Por simplicidad en este refactor, lo dejamos visual o implementamos navegación simple.
                },
                child: const Text(
                  'Ver todo',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ),
            const SizedBox(height: 16),
            
            if (recentTransactions.isEmpty)
              _buildEmptyState()
            else
              ...recentTransactions.take(5).map((transaction) {
                final category = provider.categories.firstWhere(
                  (c) => c.id == transaction.categoryId,
                  orElse: () => Category(id: 'unknown', name: 'Desconocido', kind: CategoryKind.expense),
                );
                final categoryName = category.name;

                final isExpense = transaction.amount < 0;
                final color = isExpense ? AppColors.expense : AppColors.income;
                final isTransfer = categoryName.toLowerCase().contains('transferencia');
                final finalColor = isTransfer ? AppColors.transfer : color;

                return TransactionTile(
                  categoryName: categoryName,
                  iconName: category.iconName,
                  note: transaction.notes,
                  amount: transaction.amount,
                  color: finalColor,
                  status: transaction.status,
                  dueDate: transaction.dueDate,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailsScreen(transaction: transaction),
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sin movimientos recientes',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

