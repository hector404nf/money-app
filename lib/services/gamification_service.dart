import '../models/achievement.dart';
import '../models/challenge.dart';
import '../models/transaction.dart';
import '../providers/data_provider.dart';

class GamificationService {
  static List<Achievement> getDefinitions() {
    return [
      const Achievement(
        id: 'first_step',
        title: 'Primer Paso',
        description: 'Registra tu primer movimiento.',
        iconName: 'flag',
      ),
      const Achievement(
        id: 'consistent_tracker',
        title: 'Constante',
        description: 'Registra 5 movimientos en total.',
        iconName: 'repeat',
      ),
      const Achievement(
        id: 'power_user',
        title: 'Usuario Avanzado',
        description: 'Registra 50 movimientos en total.',
        iconName: 'star',
      ),
      const Achievement(
        id: 'saver_novice',
        title: 'Ahorrador Novato',
        description: 'Ten un saldo positivo.',
        iconName: 'savings',
      ),
      const Achievement(
        id: 'millionaire',
        title: 'Millonario',
        description: 'Alcanza un saldo de 1.000.000 Gs o más.',
        iconName: 'attach_money',
      ),
       const Achievement(
        id: 'night_owl',
        title: 'Búho Nocturno',
        description: 'Registra un gasto tarde en la noche (23:00 - 05:00).',
        iconName: 'dark_mode',
      ),
      const Achievement(
        id: 'weekend_warrior',
        title: 'Finde Activo',
        description: 'Registra movimientos un fin de semana.',
        iconName: 'weekend',
      ),
      const Achievement(
        id: 'streak_7_days',
        title: 'Racha de 7 días',
        description: 'Registra movimientos por 7 días seguidos.',
        iconName: 'local_fire_department',
      ),
      const Achievement(
        id: 'streak_30_days',
        title: 'Mes Completo',
        description: 'Mantén una racha de 30 días consecutivos.',
        iconName: 'emoji_events',
      ),
      const Achievement(
        id: 'debt_snowball',
        title: 'Estratega',
        description: 'Visita la pantalla de Bola de Nieve.',
        iconName: 'ac_unit',
      ),
      const Achievement(
        id: 'planner',
        title: 'Planificador',
        description: 'Crea 5 transacciones recurrentes.',
        iconName: 'event_repeat',
      ),
      const Achievement(
        id: 'minimalist',
        title: 'Minimalista',
        description: 'Pasa una semana sin gastos menores a 20.000 Gs.',
        iconName: 'eco',
      ),
      const Achievement(
        id: 'budget_master',
        title: 'Maestro del Presupuesto',
        description: 'Completa un mes sin exceder tus presupuestos.',
        iconName: 'account_balance',
      ),
      const Achievement(
        id: 'goal_achiever',
        title: 'Cumplidor de Metas',
        description: 'Completa tu primera meta de ahorro.',
        iconName: 'check_circle',
      ),
      const Achievement(
        id: 'zero_debt',
        title: 'Libre de Deudas',
        description: 'Liquida todas tus deudas pendientes.',
        iconName: 'celebration',
      ),
      const Achievement(
        id: 'early_bird',
        title: 'Madrugador',
        description: 'Registra un movimiento antes de las 7 AM.',
        iconName: 'wb_sunny',
      ),
      const Achievement(
        id: 'voice_user',
        title: 'Comandos de Voz',
        description: 'Usa el asistente de voz 5 veces.',
        iconName: 'mic',
      ),
    ];
  }

  static List<Challenge> getChallengeDefinitions() {
    return [
      Challenge(
        id: 'no_expense_hormiga',
        title: 'Sin Gastos Hormiga',
        description: 'No registres gastos menores a 20.000 Gs durante 7 días.',
        durationDays: 7,
        type: 'no_small_expense',
      ),
      Challenge(
        id: 'savings_sprint',
        title: 'Sprint de Ahorro',
        description: 'Ahorra (Ingresos - Gastos) al menos 100.000 Gs en 7 días.',
        durationDays: 7,
        type: 'save_target',
        targetAmount: 100000,
      ),
      Challenge(
        id: 'no_eating_out',
        title: 'Cocina en Casa',
        description: 'No registres gastos en la categoría "Restaurantes" o "Comida" por 3 días.',
        durationDays: 3,
        type: 'no_category_expense',
        // Note: targetCategoryId needs to match actual category ID. 
        // Since IDs are dynamic if user created them, this is tricky.
        // We might need to check by Name or have a default system ID.
        // For now, we'll check logic dynamically by Name matching.
        targetCategoryId: 'Comida', // We will fuzzy match this
      ),
    ];
  }

  /// Checks for new unlocks. 
  /// Updates [currentList] in place (well, replaces elements) and returns the *newly unlocked* achievements.
  /// This allows the UI to show a notification.
  static List<Achievement> checkAchievements(
      List<Achievement> currentList, DataProvider provider, {bool visitedDebtSnowball = false}) {
    final newUnlocks = <Achievement>[];
    
    // We iterate by index to modify the list if needed
    for (int i = 0; i < currentList.length; i++) {
      final ach = currentList[i];
      if (ach.isUnlocked) continue;
      
      bool unlocked = false;
      
      switch (ach.id) {
        case 'first_step':
          if (provider.transactions.isNotEmpty) unlocked = true;
          break;
        case 'consistent_tracker':
          if (provider.transactions.length >= 5) unlocked = true;
          break;
        case 'saver_novice':
          if (provider.calculateTotalBalance() > 0) unlocked = true;
          break;
        case 'night_owl':
             if (provider.transactions.isNotEmpty) {
                 final hasNightTx = provider.transactions.any((t) {
                    return t.date.hour >= 23 || t.date.hour < 5;
                 });
                 if (hasNightTx) unlocked = true;
             }
             break;
        case 'weekend_warrior':
             final hasWeekendTx = provider.transactions.any((t) {
                return t.date.weekday == 6 || t.date.weekday == 7;
             });
             if (hasWeekendTx) unlocked = true;
             break;
        case 'streak_7_days':
           final dates = provider.transactions
              .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
              .toSet()
              .toList()
              ..sort();
           
           if (dates.length >= 7) {
             int streak = 1;
             for (int j = 0; j < dates.length - 1; j++) {
               if (dates[j+1].difference(dates[j]).inDays == 1) {
                 streak++;
                 if (streak >= 7) {
                   unlocked = true;
                   break;
                 }
               } else {
                 streak = 1;
               }
             }
           }
           break;
      case 'debt_snowball':
          if (visitedDebtSnowball) unlocked = true;
          break;
      }

      if (unlocked) {
        final newAch = ach.copyWith(isUnlocked: true, unlockedAt: DateTime.now());
        currentList[i] = newAch; // Update the list
        newUnlocks.add(newAch);
      }
    }
    return newUnlocks;
  }

  static bool checkChallenges(List<Challenge> challenges, DataProvider provider) {
    bool hasChanges = false;
    // Only check active challenges
    for (int i = 0; i < challenges.length; i++) {
      final ch = challenges[i];
      if (!ch.isActive || ch.isCompleted) continue;
      
      final startDate = ch.startDate!;
      final endDate = startDate.add(Duration(days: ch.durationDays));
      final now = DateTime.now();

      // Check if expired (Completed or Failed)
      // If we want "Success" check, we usually check if they SURVIVED the duration.
      // Or if they HIT the target WITHIN the duration.
      
      bool failed = false;
      bool success = false;

      // Filter transactions during the challenge period
      final txs = provider.transactions.where((t) {
        return t.date.isAfter(startDate) && t.date.isBefore(endDate);
      }).toList();

      switch (ch.type) {
        case 'no_small_expense':
          // Fail if any expense < 20000
          // "Gastos Hormiga" usually means small expenses.
          // Let's say < 20.000 Gs.
          final hasSmallExpense = txs.any((t) => t.mainType == MainType.expenses && t.amount.abs() < 20000 && t.amount.abs() > 0);
          if (hasSmallExpense) {
             failed = true;
          } else if (now.isAfter(endDate)) {
             success = true; // Survived!
          }
          break;
          
        case 'no_category_expense':
          // Fail if any expense in category
          final hasCatExpense = txs.any((t) {
            if (t.mainType != MainType.expenses) return false;
            // Lookup category name
            final cat = provider.categories.firstWhere((c) => c.id == t.categoryId, orElse: () => provider.categories.first);
            // Fuzzy match or ID match
            return cat.name.toLowerCase().contains(ch.targetCategoryId!.toLowerCase()) || cat.id == ch.targetCategoryId;
          });
          
          if (hasCatExpense) {
            failed = true;
          } else if (now.isAfter(endDate)) {
            success = true;
          }
          break;

        case 'save_target':
          // Check if Savings >= target
          double income = 0;
          double expense = 0;
          for (var t in txs) {
            if (t.mainType == MainType.incomes) income += t.amount;
            if (t.mainType == MainType.expenses) expense += t.amount.abs();
          }
          if ((income - expense) >= (ch.targetAmount ?? 0)) {
            success = true;
          } else if (now.isAfter(endDate)) {
            failed = true; // Time up and target not met
          }
          break;
      }

      if (success) {
        challenges[i] = ch.copyWith(isActive: false, isCompleted: true);
        hasChanges = true;
        // Maybe notify user?
      } else if (failed) {
        challenges[i] = ch.copyWith(isActive: false, isCompleted: false); // Failed
        hasChanges = true;
        // Reset or just mark inactive?
      }
    }
    return hasChanges;
  }

  /// Calculate current streak of consecutive days with transactions
  /// Returns the number of consecutive days (ending toda or most recent day) with at least one transaction
  static int getCurrentStreak(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;

    // Get unique dates (without time component)
    final dates = transactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending (most recent first)

    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // If the most recent transaction is not today or yesterday, streak is broken
    final mostRecent = dates.first;
    final daysDiff = todayDate.difference(mostRecent).inDays;
    
    if (daysDiff > 1) {
      return 0; // Streak is broken (more than 1 day since last transaction)
    }

    // Count consecutive days backwards from most recent
    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }
}
