import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class InvoiceParser {
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final String fullText;

  InvoiceParser({
    this.amount,
    this.date,
    this.merchant,
    required this.fullText,
  });

  static InvoiceParser parse(RecognizedText recognizedText) {
    String fullText = recognizedText.text;
    List<String> lines = recognizedText.blocks
        .expand((block) => block.lines)
        .map((line) => line.text)
        .toList();
    
    return parseFromLines(lines, fullText);
  }

  // Overload for testing with just strings
  static InvoiceParser parseFromLines(List<String> lines, String fullText) {
    String? merchant;
    if (lines.isNotEmpty) {
      // Heuristic: Merchant is often the first line, or first non-empty line
      // Ignore common header lines if any
      merchant = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    }

    DateTime? date = extractDate(fullText);
    double? amount = extractTotalAmount(lines);

    return InvoiceParser(
      amount: amount,
      date: date,
      merchant: merchant,
      fullText: fullText,
    );
  }

  static DateTime? extractDate(String text) {
    // Regex for DD/MM/YYYY or DD-MM-YYYY or YYYY-MM-DD
    // Enhanced regex to capture common separators
    final dateRegex = RegExp(
      r'\b(\d{1,2})[/\-.](?:\d{1,2})[/\-.](\d{2,4})\b|\b(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})\b',
    );

    final matches = dateRegex.allMatches(text);
    for (final match in matches) {
      try {
        String raw = match.group(0)!;
        // Normalize separators
        raw = raw.replaceAll(RegExp(r'[/\-.]'), '/');
        
        List<String> parts = raw.split('/');
        if (parts.length != 3) continue;

        int day, month, year;
        
        // Check if YYYY is first
        if (parts[0].length == 4) {
          year = int.parse(parts[0]);
          month = int.parse(parts[1]);
          day = int.parse(parts[2]);
        } else {
          day = int.parse(parts[0]);
          month = int.parse(parts[1]);
          year = int.parse(parts[2]);
          
          // Handle 2-digit year (assume 20xx)
          if (year < 100) {
            year += 2000;
          }
        }

        // Basic validation
        if (month < 1 || month > 12) continue;
        if (day < 1 || day > 31) continue;

        return DateTime(year, month, day);
      } catch (e) {
        debugPrint('Error parsing date: $e');
        continue;
      }
    }
    return null;
  }

  static double? extractTotalAmount(List<String> lines) {
    // Strategy: Look for "Total" line, or the largest number near the bottom.
    // Also consider PYG currency formatting (10.000, 100.000)
    
    double? maxAmount;
    double? totalLineAmount;

    // Regex to capture numbers with potential separators
    // e.g. 10000, 10.000, 10,000.00, 50.50
    final currencyRegex = RegExp(r'\b\d[\d.,]*\b');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase();
      
      // Check for numbers
      final matches = currencyRegex.allMatches(lines[i]);
      for (final match in matches) {
        String rawNum = match.group(0)!;
        // Filter out things that are clearly not amounts (like dates 2023-01-01 if separators were allowed, but regex above restricts to .,)
        // Also filter if it has too many separators (like IP) - dealt with in parseNumber logic potentially
        
        double? val = parseNumber(rawNum);
        
        if (val != null) {
          if (maxAmount == null || val > maxAmount) {
            maxAmount = val;
          }

          // If line contains "total", this is a strong candidate
          if (line.contains('total') || line.contains('pagar') || line.contains('suma')) {
            // If there are multiple numbers, usually the last one is the amount
            totalLineAmount = val; 
          }
        }
      }
    }

    return totalLineAmount ?? maxAmount;
  }

  static double? parseNumber(String text) {
    // Similar to NlpService logic
    String clean = text.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (clean.isEmpty) return null;

    // Remove thousands separators
    // Heuristic for PYG: 
    // 10.000 -> 10000
    // 10,000 -> 10000
    // 10.000,00 -> 10000.00
    
    if (clean.contains('.') && clean.contains(',')) {
       if (clean.lastIndexOf('.') > clean.lastIndexOf(',')) {
         // US format 1,000.00
         clean = clean.replaceAll(',', '');
       } else {
         // ES format 1.000,00
         clean = clean.replaceAll('.', '').replaceAll(',', '.');
       }
    } else if (clean.contains('.')) {
        // Check if dot is thousands or decimal
        // In PY, usually thousands: 50.000
        // Unless exactly 2 digits at end: 50.50 (cents)
        // But 50.000 could be 50k.
        // Let's assume if it has 3 digits after last dot, it's thousands.
        List<String> parts = clean.split('.');
        if (parts.last.length == 3) {
           clean = clean.replaceAll('.', '');
        } else {
           // Maybe decimal
        }
    } else if (clean.contains(',')) {
        // Comma usually decimal in ES, or thousands in US
        // If 3 digits after comma, could be thousands
        List<String> parts = clean.split(',');
        if (parts.last.length == 3) {
            clean = clean.replaceAll(',', '');
        } else {
            clean = clean.replaceAll(',', '.');
        }
    }

    return double.tryParse(clean);
  }
}
