import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/transaction_tile.dart';
import '../utils/constants.dart';
import 'transaction_details_screen.dart';

class PendingTransactionsScreen extends StatelessWidget {
  final String? monthKey;

  const PendingTransactionsScreen({super.key, this.monthKey});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);

    final pendingTransactions = provider.getPendingTransactions(monthKey: monthKey)
      ..sort((a, b) => a.date.compareTo(b.date)); // Sort ascending (earliest first)

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transacciones Pendientes'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: theme.textTheme.bodyLarge?.color,
        ),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.textTheme.headlineSmall?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: pendingTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay transacciones pendientes',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingTransactions.length,
              itemBuilder: (context, index) {
                final tx = pendingTransactions[index];
                final category = provider.categories.firstWhere((c) => c.id == tx.categoryId);
                final isTransfer = category.isTransferLike;
                final isExpense = !isTransfer && tx.amount < 0;
                final Color color = isTransfer
                    ? AppColors.transfer
                    : isExpense
                        ? AppColors.expense
                        : AppColors.income;

                return TransactionTile(
                  categoryName: category.name,
                  iconName: category.iconName,
                  note: tx.notes,
                  amount: tx.amount,
                  color: color,
                  status: tx.status,
                  dueDate: tx.dueDate,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailsScreen(transaction: tx),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
