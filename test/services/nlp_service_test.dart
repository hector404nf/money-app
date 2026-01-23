import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/models/category.dart';
import 'package:money_app/models/account.dart';
import 'package:money_app/services/nlp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('google_mlkit_entity_extractor'); // Try this first, if fails try 'google_mlkit_entity_extraction'
  // Actually, let's register for BOTH just in case, or spy on the calls.
  
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'nlp#annotate') {
          return <dynamic>[]; 
        }
        if (methodCall.method == 'nlp#manageModel') {
           return 'success';
        }
        // Return empty list for any other method that might expect a list
        return <dynamic>[];
      },
    );
    
    // Also try the other possible name
    const MethodChannel channel2 = MethodChannel('google_mlkit_entity_extraction');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel2,
      (MethodCall methodCall) async {
        if (methodCall.method == 'nlp#annotate') {
          return <dynamic>[]; 
        }
         if (methodCall.method == 'nlp#manageModel') {
           return 'success';
        }
        return <dynamic>[];
      },
    );
  });

  group('NlpService', () {
    late NlpService nlpService;
    late List<Category> categories;
    late List<Account> accounts;

    setUp(() {
      nlpService = NlpService();
      categories = [
        Category(id: '1', name: 'Supermercado', iconName: 'shopping_cart', kind: CategoryKind.expense),
        Category(id: '2', name: 'Transporte', iconName: 'directions_bus', kind: CategoryKind.expense),
      ];
      accounts = [
        Account(id: 'acc1', name: 'Efectivo', type: AccountType.cash),
        Account(id: 'acc2', name: 'Banco Ueno', type: AccountType.bank),
      ];
    });

    test('Regex fallback detects simple amount', () async {
      // Mocking the entity extractor is hard because it's a native plugin.
      // However, our NlpService logic has a fallback if the extractor returns nothing or misses the amount.
      // Since we can't easily mock the MethodChannel for ML Kit in a unit test without heavy lifting,
      // we rely on the fact that `_entityExtractor.annotateText` will likely return empty annotations in a test environment (no native implementation).
      // So this effectively tests the fallback logic.
      
      final result = await nlpService.processText("Gaste 50000 en algo", categories, accounts);
      
      expect(result.amount, equals(50000.0));
    });

    test('Regex fallback detects amount with separators', () async {
      final result = await nlpService.processText("Pago de 150.000 guaranies", categories, accounts);
      expect(result.amount, equals(150000.0));
    });

    test('Category heuristic matching', () async {
      final result = await nlpService.processText("Compre en el super", categories, accounts);
      expect(result.matchedCategoryName, equals('Supermercado'));
    });
    
    test('Category direct matching', () async {
      final result = await nlpService.processText("Gasto en transporte publico", categories, accounts);
      expect(result.matchedCategoryName, equals('Transporte'));
    });

    test('Account matching', () async {
      final result = await nlpService.processText("Pago con Banco Ueno", categories, accounts);
      expect(result.matchedAccountId, equals('acc2'));
    });

    test('Combined detection', () async {
      final result = await nlpService.processText("50.000 en el super con ueno", categories, accounts);
      expect(result.amount, equals(50000.0));
      expect(result.matchedCategoryName, equals('Supermercado'));
      expect(result.matchedAccountId, equals('acc2')); // Matches 'ueno' part of 'Banco Ueno'
    });

    test('Suggestion extraction', () async {
      final result = await nlpService.processText("Gaste 50000 en Juegos con PayPal", categories, accounts);
      expect(result.suggestedCategoryName, equals('Juegos'));
      expect(result.suggestedAccountName, equals('Paypal'));
    });

    test('Detect "en mi [Account]" pattern', () async {
      final result = await nlpService.processText("Recibi 10000 en mi itau", categories, accounts);
      expect(result.amount, equals(10000.0));
      // "itau" is not in the mock accounts list, so it should be suggested
      expect(result.suggestedAccountName, equals('Itau')); 
    });

    test('Suggestion extraction with possessive', () async {
      final result = await nlpService.processText("Gaste 50000 de mi Billetera", categories, accounts);
      expect(result.amount, equals(50000.0));
      expect(result.suggestedAccountName, equals('Billetera'));
    });

    test('Amount with "mil" suffix and Income detection', () async {
      final result = await nlpService.processText("me devolvieron un 100mil a mi cuenta de ueno", categories, accounts);
      expect(result.amount, equals(100000.0));
      expect(result.matchedAccountId, equals('acc2')); // ueno
      // Expect some category related to income or refund
      // heuristic match populates matchedCategoryName
      expect(result.matchedCategoryName, equals('Ingresos'));
      expect(result.isIncome, isTrue);
    });

    test('Intent detection: Income vs Expense', () async {
       // Income
       var result = await nlpService.processText("recibi 50000", categories, accounts);
       expect(result.isIncome, isTrue);

       result = await nlpService.processText("ingreso de 100000", categories, accounts);
       expect(result.isIncome, isTrue);
       
       // Expense
       result = await nlpService.processText("gaste 20000", categories, accounts);
       expect(result.isIncome, isFalse);

       result = await nlpService.processText("pague la luz", categories, accounts);
       expect(result.isIncome, isFalse);
       
       // Unknown
       result = await nlpService.processText("50000 en algo", categories, accounts);
       expect(result.isIncome, isNull);
    });

    test('Account extraction with "a mi" preposition', () async {
      // "me devolvieron 10000 a mi itau"
      final result = await nlpService.processText("me devolvieron 10000 a mi itau", categories, accounts);
      
      expect(result.amount, equals(10000.0));
      // Should detect income
      expect(result.isIncome, isTrue);
      // "itau" is not in the mock accounts list, so it should be in suggestedAccountName
      expect(result.suggestedAccountName, equals('Itau'));
    });

    test('Account extraction with "en mi" preposition', () async {
      // "recibi 10000 en mi itau"
      final result = await nlpService.processText("recibi 10000 en mi itau", categories, accounts);
      
      expect(result.amount, equals(10000.0));
      expect(result.isIncome, isTrue);
      expect(result.suggestedAccountName, equals('Itau'));
      // Ensure "mi" is not captured as category
      expect(result.suggestedCategoryName, isNot(equals('Mi')));
    });
  });
}
