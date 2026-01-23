import 'dart:math';
import '../models/transaction.dart';

class AnomalyService {
  /// Checks if the [amount] is an anomaly for the given [categoryId] based on [history].
  /// Returns a message if it is an anomaly, or null if it's normal.
  String? checkAnomaly(double amount, String categoryId, List<Transaction> history) {
    if (amount <= 0) return null; // Ignore income or zero

    // 1. Filter history for this category (expenses only)
    final categoryTransactions = history
        .where((t) => t.categoryId == categoryId && t.amount < 0) // Expenses are negative usually? 
        // Wait, in this app, expenses are stored as negative or positive depending on implementation?
        // Let's check Transaction model. usually expenses are negative in calculations but might be stored absolute.
        // Looking at DataProvider, expenses seem to be negative in `getIncomes` logic (it checks `amount > 0`).
        // But in `AddTransactionScreen`, user enters positive.
        // Let's assume we are checking the absolute value of the expense.
        .map((t) => t.amount.abs())
        .toList();

    if (categoryTransactions.length < 5) {
      // Not enough data to determine anomaly
      return null;
    }

    // 2. Calculate Mean
    double sum = categoryTransactions.reduce((a, b) => a + b);
    double mean = sum / categoryTransactions.length;

    // 3. Calculate Standard Deviation
    double sumSquaredDiffs = 0;
    for (var val in categoryTransactions) {
      sumSquaredDiffs += pow(val - mean, 2);
    }
    double variance = sumSquaredDiffs / categoryTransactions.length;
    double stdDev = sqrt(variance);

    // 4. Define Threshold
    // Anomaly if > Mean + 2 * StdDev
    // Also ensure it's significantly higher (e.g., > 1.5x Mean) to avoid noise on stable low expenses
    double threshold = mean + (2 * stdDev);
    
    // Fallback: If StdDev is very small (very stable expenses), use a percentage buffer (e.g. 50% more)
    if (threshold < mean * 1.5) {
      threshold = mean * 1.5;
    }

    if (amount > threshold) {
      final percentDiff = ((amount - mean) / mean * 100).toStringAsFixed(0);
      return 'Gasto inusual: ${percentDiff}% mayor al promedio (${mean.toStringAsFixed(0)})';
    }

    return null;
  }
}
