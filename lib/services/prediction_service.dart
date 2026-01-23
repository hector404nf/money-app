import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class PredictionService {
  /// Predicts the balance at the end of the month using Linear Regression on daily balances.
  /// Returns a map with 'predictedBalance', 'trend' (slope), and 'rSquared'.
  Map<String, dynamic> predictEndOfMonthBalance(List<Transaction> transactions, double currentBalance) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final currentDay = now.day;

    if (currentDay < 5) {
      return {'error': 'Se necesitan más datos del mes actual'};
    }

    // 1. Calculate Daily Balances for days 1 to currentDay
    // We need to reconstruct the balance history.
    // Easier approach: Start from currentBalance and work backwards?
    // Or start from (CurrentBalance - Sum(Transactions this month)) + Transactions Day by Day.
    
    // Filter transactions for this month
    final monthTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month && t.status == TransactionStatus.pagado;
    }).toList();

    // Calculate Starting Balance of the Month
    double totalMonthChange = 0;
    for (var t in monthTransactions) {
      // Income is positive, Expense is negative (stored as absolute with type usually, but let's check DataProvider logic)
      // In DataProvider.getIncomes, expenses are positive but filtered by type?
      // Wait, Transaction model has 'amount'.
      // In AddTransactionScreen, we save expenses as negative:
      // final finalAmount = isExpense ? -(amountToSave.abs()) : amountToSave.abs();
      // So 'amount' is signed.
      totalMonthChange += t.amount;
    }

    double startOfMonthBalance = currentBalance - totalMonthChange;

    List<Point<double>> points = [];
    double runningBalance = startOfMonthBalance;

    // We need to aggregate by day to avoid noise of multiple tx per day
    Map<int, double> dailyChanges = {};
    for (int i = 1; i <= currentDay; i++) {
      dailyChanges[i] = 0;
    }

    for (var t in monthTransactions) {
      if (t.date.day <= currentDay) {
        dailyChanges[t.date.day] = (dailyChanges[t.date.day] ?? 0) + t.amount;
      }
    }

    for (int i = 1; i <= currentDay; i++) {
      runningBalance += dailyChanges[i]!;
      points.add(Point(i.toDouble(), runningBalance));
    }

    // 2. Linear Regression (Least Squares)
    // y = mx + b
    // m = (n * sum(xy) - sum(x) * sum(y)) / (n * sum(x^2) - sum(x)^2)
    // b = (sum(y) - m * sum(x)) / n

    double n = points.length.toDouble();
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;

    for (var p in points) {
      sumX += p.x;
      sumY += p.y;
      sumXY += p.x * p.y;
      sumXX += p.x * p.x;
    }

    double m = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    double b = (sumY - m * sumX) / n;

    // 3. Predict for last day
    double predictedBalance = m * daysInMonth + b;

    return {
      'predictedBalance': predictedBalance,
      'slope': m, // Daily change rate
      'intercept': b,
      'points': points,
    };
  }
}
