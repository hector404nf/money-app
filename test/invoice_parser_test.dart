import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/utils/invoice_parser.dart';

void main() {
  group('InvoiceParser Date Extraction', () {
    test('Should extract DD/MM/YYYY', () {
      final date = InvoiceParser.extractDate('Fecha: 25/12/2023');
      expect(date, DateTime(2023, 12, 25));
    });

    test('Should extract DD-MM-YYYY', () {
      final date = InvoiceParser.extractDate('25-12-2023');
      expect(date, DateTime(2023, 12, 25));
    });

    test('Should extract YYYY-MM-DD', () {
      final date = InvoiceParser.extractDate('2023-12-25');
      expect(date, DateTime(2023, 12, 25));
    });

    test('Should extract DD/MM/YY (assume 20xx)', () {
      final date = InvoiceParser.extractDate('25/12/23');
      expect(date, DateTime(2023, 12, 25));
    });

    test('Should return null for invalid date', () {
      final date = InvoiceParser.extractDate('No date here');
      expect(date, null);
    });
  });

  group('InvoiceParser Amount Extraction', () {
    test('Should extract simple amount', () {
      final amount = InvoiceParser.extractTotalAmount(['Total: 10000']);
      expect(amount, 10000.0);
    });

    test('Should extract amount with thousands separator (dot)', () {
      final amount = InvoiceParser.extractTotalAmount(['Total: 10.000']);
      expect(amount, 10000.0);
    });

    test('Should extract amount with thousands separator (comma)', () {
      final amount = InvoiceParser.extractTotalAmount(['Total: 10,000']);
      expect(amount, 10000.0);
    });

    test('Should extract amount with decimal (comma)', () {
      final amount = InvoiceParser.extractTotalAmount(['Total: 10,50']);
      expect(amount, 10.50);
    });

    test('Should prioritize "Total" line', () {
      final lines = [
        'Item 1 ... 5000',
        'Item 2 ... 3000',
        'Total ... 8000',
        'Gracias por su compra'
      ];
      final amount = InvoiceParser.extractTotalAmount(lines);
      expect(amount, 8000.0);
    });

    test('Should pick largest number if no "Total" keyword', () {
      final lines = [
        'Item 1 ... 5000',
        'Item 2 ... 3000',
        '8000' // Sum
      ];
      final amount = InvoiceParser.extractTotalAmount(lines);
      expect(amount, 8000.0);
    });

    test('Should handle PYG large numbers', () {
      final amount = InvoiceParser.extractTotalAmount(['1.500.000']);
      expect(amount, 1500000.0);
    });
  });

  group('InvoiceParser Merchant Extraction', () {
    test('Should extract first non-empty line', () {
      final parser = InvoiceParser.parseFromLines([
        '', 
        'Supermercado Stock', 
        'Av. Mariscal Lopez'
      ], '');
      expect(parser.merchant, 'Supermercado Stock');
    });
  });

  group('InvoiceParser Integration', () {
    test('Should parse full invoice', () {
      final lines = [
        'Biggie Express',
        'RUC: 8000000-1',
        'Fecha: 01/02/2026',
        'Coca Cola ... 8.000',
        'Pan ... 5.000',
        'Total a Pagar: 13.000',
        'Gracias'
      ];
      final fullText = lines.join('\n');
      
      final result = InvoiceParser.parseFromLines(lines, fullText);
      
      expect(result.merchant, 'Biggie Express');
      expect(result.date, DateTime(2026, 2, 1));
      expect(result.amount, 13000.0);
    });
  });
}
