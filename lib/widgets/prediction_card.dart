import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/prediction_service.dart';
import '../utils/constants.dart';

class PredictionCard extends StatelessWidget {
  final List<Transaction> transactions;
  final double currentBalance;

  const PredictionCard({
    super.key,
    required this.transactions,
    required this.currentBalance,
  });

  String _formatCurrency(double amount, NumberFormat formatter) {
    try {
      return formatter.format(amount);
    } catch (e) {
      // Fallback if locale data is missing
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Only show if day > 5 to have enough data
    if (now.day <= 5) return const SizedBox.shrink();

    final prediction = PredictionService().predictEndOfMonthBalance(transactions, currentBalance);

    if (prediction.containsKey('error')) {
        return const SizedBox.shrink();
    }

    final predictedBalance = prediction['predictedBalance'] as double;
    final slope = prediction['slope'] as double;

    if (!predictedBalance.isFinite || !slope.isFinite) {
      return const SizedBox.shrink();
    }
    
    NumberFormat currencyFormat;
    try {
      currencyFormat = NumberFormat.currency(locale: 'es_PY', symbol: 'Gs', decimalDigits: 0);
    } catch (_) {
      currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    }
    
    final isTrendPositive = slope > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Proyección Fin de Mes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              /* Container(
                color: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                /* decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  // borderRadius: BorderRadius.circular(12),
                ), */
                child: const Text(
                  'IA Beta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ), */
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(predictedBalance, currencyFormat),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isTrendPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Tendencia: ${_formatCurrency(slope, currencyFormat)} / día',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
