import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    
    // Fetch fresh data in case it changed (though in this simple app passing object is usually fine, 
    // better to find by ID if we want live updates, but let's stick to the passed object for display 
    // and use ID for actions)
    
    final category = provider.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => Category(id: 'unknown', name: 'Desconocido', kind: CategoryKind.expense),
    );
    
    final account = provider.accounts.firstWhere(
      (a) => a.id == transaction.accountId,
      orElse: () {
        // Si no es una cuenta, buscamos si es una meta
        try {
          final goal = provider.goals.firstWhere((g) => g.id == transaction.accountId);
          return Account(
            id: goal.id,
            name: goal.name,
            type: AccountType.savings,
            initialBalance: 0,
          );
        } catch (_) {
          return Account(
            id: 'unknown',
            name: 'Cuenta desconocida',
            type: AccountType.bank,
            initialBalance: 0,
          );
        }
      },
    );

    final isExpense = transaction.amount < 0;
    final color = isExpense ? AppColors.expense : AppColors.income;
    final isTransfer = category.name.toLowerCase().contains('transferencia');
    final finalColor = isTransfer ? AppColors.transfer : color;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Icon & Amount
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [AppShadows.soft],
              ),
              child: Icon(
                category.iconName != null ? IconHelper.getIconByName(category.iconName!) : IconHelper.getCategoryIcon(category.name),
                size: 48,
                color: finalColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              category.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₲ ${transaction.amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: finalColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [AppShadows.soft],
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, 'Fecha', _formatDate(transaction.date)),
                  const Divider(height: 32),
                  _buildDetailRow(context, 'Cuenta', account.name),
                  const Divider(height: 32),
                  _buildDetailRow(context, 'Estado', transaction.status.name.toUpperCase(), 
                    valueColor: transaction.status == TransactionStatus.pagado 
                      ? Colors.green 
                      : Colors.orange
                  ),
                  if (transaction.dueDate != null) ...[
                     const Divider(height: 32),
                    _buildDetailRow(context, 'Vence', _formatDate(transaction.dueDate!)),
                  ],
                  if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                    const Divider(height: 32),
                    _buildDetailRow(context, 'Nota', transaction.notes!),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Actions
            if (transaction.status != TransactionStatus.pagado)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.updateTransactionStatus(transaction.id, TransactionStatus.pagado);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marcado como pagado')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar como Pagado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              
             if (transaction.status == TransactionStatus.pagado)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.updateTransactionStatus(transaction.id, TransactionStatus.pendiente);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marcado como pendiente')),
                    );
                  },
                  icon: const Icon(Icons.undo),
                  label: const Text('Marcar como Pendiente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmDelete(BuildContext context, DataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Estás seguro de que quieres eliminar este movimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTransaction(transaction.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close details screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Movimiento eliminado')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
