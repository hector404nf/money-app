import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/models/transaction.dart';
import 'package:money_app/services/anomaly_service.dart';

void main() {
  late AnomalyService anomalyService;

  setUp(() {
    anomalyService = AnomalyService();
  });

  group('AnomalyService', () {
    test('returns null if amount is <= 0', () {
      final result = anomalyService.checkAnomaly(0, 'cat1', []);
      expect(result, isNull);
      
      final result2 = anomalyService.checkAnomaly(-100, 'cat1', []);
      expect(result2, isNull);
    });

    test('returns null if not enough history (less than 5 txs)', () {
      final history = [
        Transaction(id: '1', amount: -50, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
        Transaction(id: '2', amount: -50, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
      ];
      final result = anomalyService.checkAnomaly(100, 'cat1', history);
      expect(result, isNull);
    });

    test('returns null for normal expense', () {
      // Mean = 100, StdDev = 0 (all same)
      // Threshold = 100 + (2*0) = 100. But min threshold is 1.5 * Mean = 150.
      final history = List.generate(10, (i) => 
        Transaction(id: '$i', amount: -100, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado)
      );

      // Amount 120 < 150
      final result = anomalyService.checkAnomaly(120, 'cat1', history);
      expect(result, isNull);
    });

    test('returns anomaly message for high expense', () {
      // Mean = 100
      final history = List.generate(10, (i) => 
        Transaction(id: '$i', amount: -100, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado)
      );

      // Threshold min is 150.
      // Amount 200 > 150.
      final result = anomalyService.checkAnomaly(200, 'cat1', history);
      expect(result, isNotNull);
      expect(result, contains('Gasto inusual'));
      expect(result, contains('100% mayor')); // (200-100)/100 = 100%
    });

    test('calculates anomaly correctly with variable history', () {
      // Values: 10, 20, 10, 20, 15.
      // Mean = 75 / 5 = 15.
      // Diffs: -5, 5, -5, 5, 0. Sq: 25, 25, 25, 25, 0. SumSq: 100.
      // Variance = 20. StdDev = sqrt(20) ~= 4.47.
      // Threshold = 15 + (2 * 4.47) = 15 + 8.94 = 23.94.
      // Min Threshold = 15 * 1.5 = 22.5.
      // Final Threshold = 23.94.
      
      final history = [
        Transaction(id: '1', amount: -10, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
        Transaction(id: '2', amount: -20, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
        Transaction(id: '3', amount: -10, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
        Transaction(id: '4', amount: -20, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
        Transaction(id: '5', amount: -15, categoryId: 'cat1', date: DateTime.now(), mainType: MainType.expenses, accountId: 'acc1', monthKey: '2023-01', status: TransactionStatus.pagado),
      ];

      // 25 > 23.94 -> Anomaly
      final result = anomalyService.checkAnomaly(25, 'cat1', history);
      expect(result, isNotNull);

      // 23 < 23.94 -> Normal
      final result2 = anomalyService.checkAnomaly(23, 'cat1', history);
      expect(result2, isNull);
    });
  });
}
