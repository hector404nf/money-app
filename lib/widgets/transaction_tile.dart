import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final String categoryName;
  final String? iconName;
  final String? note;
  final double amount;
  final Color color;
  final VoidCallback? onTap;
  final TransactionStatus status;
  final DateTime? dueDate;

  const TransactionTile({
    super.key,
    required this.categoryName,
    this.iconName,
    this.note,
    required this.amount,
    required this.color,
    this.onTap,
    this.status = TransactionStatus.pagado,
    this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconName != null ? IconHelper.getIconByName(iconName!) : IconHelper.getCategoryIcon(categoryName),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (note != null && note!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (status != TransactionStatus.pagado) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded, 
                              size: 12, 
                              color: status == TransactionStatus.pendiente ? Colors.orange : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status == TransactionStatus.pendiente ? 'PENDIENTE' : 'PROGRAMADO',
                              style: TextStyle(
                                color: status == TransactionStatus.pendiente ? Colors.orange : Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (dueDate != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Vence: ${dueDate!.day}/${dueDate!.month}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    '₲ ${amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
