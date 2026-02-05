import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/models/category_rule.dart';
import 'package:money_app/models/category.dart';
import 'package:money_app/models/account.dart';
import 'package:money_app/services/nlp_service.dart';

void main() {
  group('NLP Service Rules', () {
    late NlpService nlpService;
    late List<Category> categories;
    late List<Account> accounts;
    late List<CategoryRule> rules;

    setUp(() {
      nlpService = NlpService();
      
      categories = [
        Category(id: 'cat_uber', name: 'Transporte', kind: CategoryKind.expense),
        Category(id: 'cat_food', name: 'Comida', kind: CategoryKind.expense),
        Category(id: 'cat_salary', name: 'Sueldo', kind: CategoryKind.income),
      ];
      
      accounts = [
        Account(id: 'acc1', name: 'Banco', type: AccountType.bank),
      ];

      rules = [
        CategoryRule(
          id: 'rule1',
          rulePattern: 'Uber',
          categoryId: 'cat_uber',
          active: true,
          isStrict: false,
        ),
        CategoryRule(
          id: 'rule2',
          rulePattern: 'McDonalds',
          categoryId: 'cat_food',
          active: true,
          isStrict: false,
        ),
        CategoryRule(
          id: 'rule3',
          rulePattern: 'Nómina',
          categoryId: 'cat_salary',
          active: true,
          isStrict: true, // Strict match
        ),
        CategoryRule(
          id: 'rule4',
          rulePattern: 'Inactive Rule',
          categoryId: 'cat_food',
          active: false,
          isStrict: false,
        ),
      ];
    });

    test('Should apply simple rule (contains)', () async {
      final result = await nlpService.processText(
        'Pago de Uber viaje',
        categories,
        accounts,
        rules: rules,
      );
      
      expect(result.matchedCategoryName, 'Transporte');
    });

    test('Should apply simple rule (case insensitive)', () async {
      final result = await nlpService.processText(
        'pago de uber viaje',
        categories,
        accounts,
        rules: rules,
      );
      
      expect(result.matchedCategoryName, 'Transporte');
    });

    test('Should apply strict rule (exact word match)', () async {
      final result = await nlpService.processText(
        'Ingreso de Nómina mensual',
        categories,
        accounts,
        rules: rules,
      );
      
      expect(result.matchedCategoryName, 'Sueldo');
    });

    test('Should NOT apply strict rule if partial match', () async {
      // "Nómina" is strict. "Nóminas" shouldn't match.
      
      final result = await nlpService.processText(
        'Pago de Nóminas extras',
        categories,
        accounts,
        rules: rules,
      );
      
      // Should not match 'Sueldo' because 'Nóminas' != 'Nómina' in strict mode
      expect(result.matchedCategoryName, isNot('Sueldo'));
    });

    test('Should ignore inactive rules', () async {
      final result = await nlpService.processText(
        'Gasto en Inactive Rule test',
        categories,
        accounts,
        rules: rules,
      );
      
      expect(result.matchedCategoryName, isNull);
    });

    test('Should prefer rule over default NLP keyword if rule exists', () async {
      final weirdRule = CategoryRule(
        id: 'rule_override',
        rulePattern: 'Restaurante',
        categoryId: 'cat_uber', // Map Restaurant to Transport intentionally
        active: true,
      );
      
      // "Restaurante" might not be in heuristic match, but let's assume "Comida" is.
      // But here we are testing rule application priority.
      // processText applies rules FIRST.
      
      final result = await nlpService.processText(
        'Cena en Restaurante',
        categories,
        accounts,
        rules: [weirdRule, ...rules],
      );
      
      expect(result.matchedCategoryName, 'Transporte');
    });
  });
}
