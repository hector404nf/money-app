import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'edit_account_screen.dart';
import 'transaction_details_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    
    // Find account safely
    final accountIndex = provider.accounts.indexWhere((a) => a.id == accountId);
    if (accountIndex == -1) {
       return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Cuenta no encontrada')),
      );
    }
    final account = provider.accounts[accountIndex];

    final transactions = provider.transactions
        .where((t) => t.accountId == accountId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentBalance = provider.getAccountBalance(accountId);
    final currencyFormat = NumberFormat('#,###', 'es_PY');

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              AddAccountModal.show(context, account: account);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Icon(account.type.icon, size: 48, color: account.type.color),
                const SizedBox(height: 16),
                Text(
                  'Saldo Actual',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₲ ${currencyFormat.format(currentBalance)}',
                  style: TextStyle(
                    color: currentBalance >= 0 ? (isDark ? Colors.white : Colors.black) : AppColors.expense,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (account.type == AccountType.card) ...[
                   const SizedBox(height: 16),
                   _buildCreditCardInfo(context, account, currentBalance, provider),
                ],
              ],
            ),
          ),
          
          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Sin movimientos',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final category = provider.categories.firstWhere(
                        (c) => c.id == transaction.categoryId,
                        orElse: () => Category(id: 'unknown', name: 'Desconocido', kind: CategoryKind.expense),
                      );

                      final isExpense = transaction.amount < 0;
                      final color = isExpense ? AppColors.expense : AppColors.income;
                      final isTransfer = category.name.toLowerCase().contains('transferencia');
                      final finalColor = isTransfer ? AppColors.transfer : color;

                      return TransactionTile(
                        categoryName: category.name,
                        iconName: category.iconName,
                        note: transaction.notes,
                        amount: transaction.amount,
                        color: finalColor,
                        status: transaction.status,
                        dueDate: transaction.dueDate,
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailsScreen(transaction: transaction),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardInfo(BuildContext context, Account account, double currentBalance, DataProvider provider) {
    if (account.creditLimit == null) return const SizedBox.shrink();

    final limit = account.creditLimit!;
    final available = limit + currentBalance; // currentBalance is negative for expenses
    final progress = (available / limit).clamp(0.0, 1.0);
    final currencyFormat = NumberFormat('#,###', 'es_PY');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate Projection
    double? projectedClosing;
    if (account.closingDay != null) {
      final today = DateTime.now();
      int endDay = account.closingDay!;
      int endMonth = today.month;
      int endYear = today.year;

      if (today.day > endDay) {
        endMonth++;
        if (endMonth > 12) {
          endMonth = 1;
          endYear++;
        }
      }

      int maxDays = DateUtils.getDaysInMonth(endYear, endMonth);
      int actualEndDay = (endDay > maxDays) ? maxDays : endDay;
      final cycleEnd = DateTime(endYear, endMonth, actualEndDay, 23, 59, 59);

      // Start date calculation
      int startMonth = endMonth - 1;
      int startYear = endYear;
      if (startMonth < 1) {
        startMonth = 12;
        startYear--;
      }
      int maxDaysStart = DateUtils.getDaysInMonth(startYear, startMonth);
      int actualStartEndDay = (endDay > maxDaysStart) ? maxDaysStart : endDay;
      final cycleStart = DateTime(startYear, startMonth, actualStartEndDay).add(const Duration(days: 1));
      final finalCycleStart = DateTime(cycleStart.year, cycleStart.month, cycleStart.day);

      // Sum transactions in range (Expenses only)
      projectedClosing = provider.transactions
          .where((t) => t.accountId == account.id &&
              t.date.isAfter(finalCycleStart.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(cycleEnd.add(const Duration(seconds: 1))) &&
              t.amount < 0)
          .fold<double>(0.0, (sum, t) => sum + t.amount);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Disponible: ₲ ${currencyFormat.format(available)}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
            Text('Límite: ₲ ${currencyFormat.format(limit)}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
          ],
        ),
        if (projectedClosing != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Proyección Cierre: ₲ ${currencyFormat.format(projectedClosing.abs())}',
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(account.type.color),
          borderRadius: BorderRadius.circular(4),
        ),
        if (account.closingDay != null || account.dueDay != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (account.closingDay != null)
                _buildDateBadge(context, 'Cierre', account.closingDay!),
              if (account.closingDay != null && account.dueDay != null)
                const SizedBox(width: 12),
              if (account.dueDay != null)
                 _buildDateBadge(context, 'Vence', account.dueDay!),
            ],
          ),
        ],
        
        if (currentBalance < 0) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Pagar Tarjeta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: account.type.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showPaymentDialog(context, account, currentBalance),
            ),
          ),
        ],
      ],
    );
  }

  void _showPaymentDialog(BuildContext context, Account cardAccount, double debtAmount) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    // Accounts that are NOT the card itself
    final sourceAccounts = provider.accounts.where((a) => a.id != cardAccount.id).toList();

    if (sourceAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes otras cuentas para realizar el pago')),
      );
      return;
    }

    String? selectedSourceId = sourceAccounts.first.id;
    final amountController = TextEditingController(text: debtAmount.abs().toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Pagar Tarjeta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedSourceId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cuenta Origen',
                  border: OutlineInputBorder(),
                ),
                items: sourceAccounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(
                    '${a.name} (₲ ${provider.getAccountBalance(a.id).toStringAsFixed(0)})',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
                onChanged: (v) => setState(() => selectedSourceId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto a Pagar', 
                  prefixText: '₲ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.replaceAll('.', ''));
                if (amount == null || amount <= 0) return;
                if (selectedSourceId == null) return;

                try {
                  provider.addTransfer(
                    amount: amount,
                    fromAccountId: selectedSourceId!,
                    toAccountId: cardAccount.id,
                    date: DateTime.now(),
                    notes: 'Pago de Tarjeta ${cardAccount.name}',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pago realizado con éxito')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Pagar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge(BuildContext context, String label, int day) {
     final theme = Theme.of(context);
     final isDark = theme.brightness == Brightness.dark;
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
         borderRadius: BorderRadius.circular(8),
       ),
       child: Text(
         '$label: Día $day',
         style: TextStyle(
           fontSize: 11, 
           fontWeight: FontWeight.w500,
           color: isDark ? Colors.white70 : Colors.black87,
         ),
       ),
     );
  }
}
