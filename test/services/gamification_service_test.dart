import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/models/achievement.dart';
import 'package:money_app/models/transaction.dart';
import 'package:money_app/services/gamification_service.dart';
import 'package:money_app/providers/data_provider.dart';
import 'package:hive/hive.dart';
import 'dart:io';

// Create a Fake DataProvider to avoid mocking complex ChangeNotifier
class FakeDataProvider extends DataProvider {
  final List<Transaction> _fakeTransactions = [];
  
  @override
  List<Transaction> get transactions => _fakeTransactions;

  @override
  double calculateTotalBalance() {
    // Simple logic for test
    double total = 0;
    for (var t in _fakeTransactions) {
      total += t.amount;
    }
    return total;
  }

  void addFakeTransaction(Transaction t) {
    _fakeTransactions.add(t);
  }
}

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    // Initialize Hive for tests
    hiveTestDir = await Directory.systemTemp.createTemp('money_app_gamification_test_');
    Hive.init(hiveTestDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveTestDir.delete(recursive: true);
  });

  group('GamificationService', () {
    late FakeDataProvider provider;
    late List<Achievement> achievements;

    setUp(() {
      provider = FakeDataProvider();
      achievements = GamificationService.getDefinitions();
    });

    test('unlocks "Primer Paso" on first transaction', () {
      final txDate = DateTime(2023, 1, 2, 12, 0); // Monday, not weekend, not night
      provider.addFakeTransaction(Transaction(
        id: '1',
        amount: -10,
        categoryId: 'cat',
        accountId: 'acc',
        date: txDate,
        mainType: MainType.expenses,
        monthKey: '2023-01',
        status: TransactionStatus.pagado,
      ));

      final newUnlocks = GamificationService.checkAchievements(achievements, provider);
      
      expect(newUnlocks.length, 1);
      expect(newUnlocks.first.id, 'first_step');
      expect(achievements.firstWhere((a) => a.id == 'first_step').isUnlocked, true);
    });

    test('unlocks "Constante" on 5th transaction', () {
      final txDate = DateTime(2023, 1, 2, 12, 0); // Monday, not weekend, not night
      for (int i = 0; i < 4; i++) {
        provider.addFakeTransaction(Transaction(id: '$i', amount: -10, categoryId: 'cat', accountId: 'acc', date: txDate, mainType: MainType.expenses, monthKey: '2023-01', status: TransactionStatus.pagado));
      }
      
      // Check at 4
      var unlocks = GamificationService.checkAchievements(achievements, provider);
      // "Primer Paso" should be unlocked at 1st transaction.
      // So here we expect 1 unlock if we haven't checked before.
      expect(unlocks.length, 1); 
      expect(unlocks.first.id, 'first_step');

      // Add 5th
      provider.addFakeTransaction(Transaction(id: '5', amount: -10, categoryId: 'cat', accountId: 'acc', date: txDate, mainType: MainType.expenses, monthKey: '2023-01', status: TransactionStatus.pagado));
      
      // Now "Constante" should unlock. "Primer Paso" is already unlocked in the list.
      
      unlocks = GamificationService.checkAchievements(achievements, provider);
      expect(unlocks.length, 1); // Only Constant
      expect(unlocks.first.id, 'consistent_tracker');
    });

    test('unlocks "Ahorrador Novato" on positive balance', () {
      final txDate = DateTime(2023, 1, 2, 12, 0); // Monday, not weekend, not night
      provider.addFakeTransaction(Transaction(
        id: '1',
        amount: 100, // Income
        categoryId: 'cat',
        accountId: 'acc',
        date: txDate,
        mainType: MainType.incomes,
        monthKey: '2023-01',
        status: TransactionStatus.pagado,
      ));

      final unlocks = GamificationService.checkAchievements(achievements, provider);
      expect(unlocks.any((a) => a.id == 'saver_novice'), true);
    });

    test('unlocks "Búho Nocturno" on late night transaction', () {
      final nightDate = DateTime(2023, 1, 1, 23, 30); // 23:30
      provider.addFakeTransaction(Transaction(
        id: '1',
        amount: -10,
        categoryId: 'cat',
        accountId: 'acc',
        date: nightDate,
        mainType: MainType.expenses,
        monthKey: '2023-01',
        status: TransactionStatus.pagado,
      ));

      final unlocks = GamificationService.checkAchievements(achievements, provider);
      expect(unlocks.any((a) => a.id == 'night_owl'), true);
    });

    test('unlocks "Finde Activo" on weekend transaction', () {
      final weekendDate = DateTime(2023, 1, 7, 12, 00); // Jan 7 2023 was Saturday
      provider.addFakeTransaction(Transaction(
        id: '1',
        amount: -10,
        categoryId: 'cat',
        accountId: 'acc',
        date: weekendDate,
        mainType: MainType.expenses,
        monthKey: '2023-01',
        status: TransactionStatus.pagado,
      ));

      final unlocks = GamificationService.checkAchievements(achievements, provider);
      expect(unlocks.any((a) => a.id == 'weekend_warrior'), true);
    });
  });
}
