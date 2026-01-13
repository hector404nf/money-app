import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/category.dart';
import '../widgets/hero_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/transaction_tile.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';
import 'transaction_details_screen.dart';
import 'sync_screen.dart';
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Resumen Financiero',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedMonthKey,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary, size: 20),
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    isDense: true,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todo el historial'),
                      ),
                      ...provider.availableMonthKeys.map(
                        (key) => DropdownMenuItem<String?>(
                          value: key,
                          child: Text(key),
                        ),
                      ),
                    ],
                    onChanged: (value) => provider.setSelectedMonthKey(value),
                  ),
                ),
              ),
            ],
            ),
            
            const SizedBox(height: 24),
            
            HeroCard(amount: projectedBalance),
            
            const SizedBox(height: 32),

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reportes próximamente')),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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

