import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import 'edit_account_screen.dart';
import 'sync_screen.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/goal_card.dart';
import 'add_goal_screen.dart';
import 'add_transaction_screen.dart';
import '../utils/icon_helper.dart';
import 'categories_screen.dart';
import 'transaction_details_screen.dart';

class AccountsTab extends StatelessWidget {
  const AccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalBalance = provider.accounts.fold(
      0.0, 
      (sum, account) => sum + provider.getAccountBalance(account.id)
    );

    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        children: [
          // Header
          Text(
            'Cuentas',
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineMedium?.color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Administra tus cuentas y saldos',
            style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Total Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Balance Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                      'Total: Gs. ${totalBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.0,
                          ),
                    ),
                const SizedBox(height: 8),
                Text(
                  'Disponible en todas las cuentas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis cuentas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              IconButton(
                key: const Key('add_account_button'),
                onPressed: () => AddAccountModal.show(context),
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                tooltip: 'Agregar cuenta',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accounts List
          ...provider.accounts.map((account) {
            final balance = provider.getAccountBalance(account.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => AddAccountModal.show(context, account: account),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: account.type.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            account.type.icon,
                            color: account.type.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                account.type.displayName,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Gs. ${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 16,
                              ),
                            ),
                            if (account.initialBalance > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Inicial: ${account.initialBalance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          Builder(
            builder: (context) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final upcomingBills = provider.transactions.where((t) {
                if (t.status == TransactionStatus.pagado) return false;
                if (t.amount >= 0) return false;
                if (t.dueDate == null) return false;
                final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                return !due.isBefore(today);
              }).toList()
                ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

              if (upcomingBills.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Cuentas por pagar',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${upcomingBills.length} en camino',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: upcomingBills.take(5).map((tx) {
                        Category? category;
                        try {
                          category = provider.categories.firstWhere(
                            (c) => c.id == tx.categoryId,
                          );
                        } catch (_) {
                          category = null;
                        }
                        final isInstallment = tx.isRecurring && tx.frequency == RecurringFrequency.monthly;
                        final title = category?.name ?? 'Gasto';
                        final icon = IconHelper.getIconByName(category?.iconName ?? 'category');
                        final subtitleParts = <String>[];
                        if (isInstallment) {
                          subtitleParts.add('Cuota mensual');
                        } else {
                          subtitleParts.add('Pago único');
                        }
                        if (tx.dueDate != null) {
                          subtitleParts.add('Vence: ${tx.dueDate!.day}/${tx.dueDate!.month}');
                        }
                        final subtitle = subtitleParts.join(' • ');

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (category != null ? AppColors.primary : Colors.grey).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: category != null ? AppColors.primary : Colors.grey,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₲ ${tx.amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'), (Match m) => '${m[1]}.')}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expense,
                                ),
                              ),
                              if (isInstallment)
                                Text(
                                  'Cuota',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.expense,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TransactionDetailsScreen(transaction: tx),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),

          // Add Account Button (Bottom List)
          if (provider.accounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes cuentas registradas',
                      style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => AddAccountModal.show(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear mi primera cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 32),

          // Metas Header
          if (provider.goals.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Metas de Ahorro',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  key: const Key('add_goal_text_button'),
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
                    );
                  },
                  child: const Text(
                    'Nueva Meta',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...provider.goals.map((goal) => GoalCard(
              name: goal.name,
              targetAmount: goal.targetAmount,
              currentAmount: goal.currentAmount,
              deadline: goal.deadline,
              colorValue: goal.colorValue,
              iconName: goal.iconName,
              onTap: () => _showGoalDetails(context, goal, provider),
            )),
          ] else ...[
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Metas de Ahorro',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                 IconButton(
                    key: const Key('add_goal_icon_button'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddGoalScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                 ),
              ],
             ),
             Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(
                 color: isDark ? theme.cardTheme.color : Colors.grey[50],
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
               ),
               child: Center(
                 child: Text(
                   'No tienes metas de ahorro activas',
                   style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                 ),
               ),
             ),
          ],
          
          const SizedBox(height: 32),
          
          // Settings Section (Placeholder)
          Text(
            'Configuración',
            style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.category_outlined, color: Colors.blue),
                  ),
                  title: const Text('Categorías'),
                  subtitle: const Text('Gestionar categorías de gastos e ingresos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_outlined, color: Colors.purple),
                  ),
                  title: const Text('Notificaciones'),
                  subtitle: const Text('Configurar alertas y recordatorios'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                  onTap: () {
                     // TODO: Implement Notifications
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente: Configuración de Notificaciones')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_upload_outlined, color: Colors.orange),
                  ),
                  title: const Text('Copia de Seguridad'),
                  subtitle: const Text('Sincronizar datos con la nube'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SyncScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  void _showGoalDetails(BuildContext context, Goal goal, DataProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(goal.colorValue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        IconHelper.getIconByName(goal.iconName),
                        color: Color(goal.colorValue),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          if (goal.deadline != null)
                            Text(
                              'Vence el ${goal.deadline!.day}/${goal.deadline!.month}/${goal.deadline!.year}',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Progress
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: goal.currentAmount / goal.targetAmount,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        color: Color(goal.colorValue),
                        minHeight: 20,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gs. ${goal.currentAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(goal.colorValue),
                        ),
                      ),
                      Text(
                        'Gs. ${goal.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              initialFlow: TransactionFlow.transfer,
                              initialToAccountId: goal.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Fondos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                         Navigator.pop(context);
                         Navigator.push(
                           context,
                           MaterialPageRoute(
                             builder: (_) => AddGoalScreen(goal: goal),
                           ),
                         );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(context, goal, provider);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _confirmDelete(BuildContext context, Goal goal, DataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Meta'),
        content: Text('¿Estás seguro de eliminar la meta "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteGoal(goal.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
