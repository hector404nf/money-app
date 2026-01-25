import 'package:flutter/foundation.dart' hide Category;
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import '../models/category.dart';
import '../models/account.dart';

class NlpResult {
  final double? amount;
  final String? currency;
  final DateTime? date;
  final String? matchedCategoryName;
  final String? matchedAccountId;
  final String? suggestedCategoryName;
  final String? suggestedAccountName;
  final String? concept;
  final bool? isIncome;
  
  NlpResult({
    this.amount, 
    this.currency, 
    this.date, 
    this.matchedCategoryName, 
    this.matchedAccountId,
    this.suggestedCategoryName,
    this.suggestedAccountName,
    this.concept,
    this.isIncome,
  });
  
  @override
  String toString() {
    return 'NlpResult(amount: $amount, currency: $currency, date: $date, category: $matchedCategoryName, accountId: $matchedAccountId, suggestedCategory: $suggestedCategoryName, suggestedAccount: $suggestedAccountName, concept: $concept, isIncome: $isIncome)';
  }
}

class NlpService {
  // Use Spanish model for parsing
  final _entityExtractor = EntityExtractor(language: EntityExtractorLanguage.spanish);
  bool _isModelDownloaded = false;

  Future<bool> ensureModelDownloaded() async {
    try {
      final modelManager = EntityExtractorModelManager();
      final result = await modelManager.downloadModel(EntityExtractorLanguage.spanish.name);
      _isModelDownloaded = result;
      return result;
    } catch (e) {
      debugPrint('Error downloading NLP model: $e');
      return false;
    }
  }

  Future<NlpResult> processText(String text, List<Category> categories, List<Account> accounts) async {
    try {
        if (!_isModelDownloaded) {
          await ensureModelDownloaded();
        }
    } catch (e) {
        debugPrint('Model download/check failed: $e');
        // Continue to regex/heuristic fallback
    }

    List<EntityAnnotation> annotations = [];
    try {
      annotations = await _entityExtractor.annotateText(text);
    } catch (e) {
      debugPrint('ML Kit Annotation failed: $e');
      // Continue with empty annotations to trigger fallback
    }
    
    double? amount;
    String? currency;
    DateTime? date;
    
    for (final annotation in annotations) {
      for (final entity in annotation.entities) {
        if (entity is MoneyEntity) {
          // Parse amount from rawValue as fallback/simplification
          // Remove non-numeric characters except . and ,
          String clean = entity.rawValue.replaceAll(RegExp(r'[^0-9.,]'), '');
          // Normalize comma to dot if needed (assuming 1,000.00 or 1.000,00 format is complex, 
          // but simple regex is better than missing fields)
          // Actually, let's try to use integerPart and assume fractionalPart is named 'fraction' if we want to guess, 
          // but parsing rawValue is safer for now.
          clean = clean.replaceAll(',', '.'); // naive
          amount = double.tryParse(clean);
          currency = entity.unnormalizedCurrency;
        } else if (entity is DateTimeEntity) {
          date = DateTime.fromMillisecondsSinceEpoch(entity.timestamp);
        }
      }
    }
    
        // Regex Fallback for Amount if ML Kit failed
    if (amount == null) {
        // Look for numbers like 50.000, 50000, 50,000, 100mil, 100k
        // Matches: 50000, 50.000, 50,000, 50000.00, 50000,00
        // Improved Regex:
        // 1. Formatted with thousands separators (dot or comma) and optional decimals: \d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?
        // 2. Plain digits: \d+
        // 3. Digits followed by 'mil' or 'k' (case insensitive): \d+\s*(?:mil|k)
        
        final regex = RegExp(r'\b(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?|\d+\s*(?:mil|k))\b', caseSensitive: false);
        final matches = regex.allMatches(text);
        
        double maxVal = 0;
        for (final match in matches) {
            String raw = match.group(0)!;
            String lowerRaw = raw.toLowerCase();
            double multiplier = 1.0;
            
            if (lowerRaw.contains('mil')) {
                multiplier = 1000.0;
                raw = lowerRaw.replaceAll('mil', '').trim();
            } else if (lowerRaw.contains('k')) {
                multiplier = 1000.0;
                raw = lowerRaw.replaceAll('k', '').trim();
            }

            String clean = raw;
            
            // Heuristic to handle "50.000" (50k) vs "50.00" (50)
            // If it has 3 decimal places, it's likely a thousands separator (e.g. PYG).
            // If it has 2, it could be cents or thousands separator depending on locale.
            // In PYG, we don't usually use cents. 50.000 is 50k. 50,000 is 50k.
            // 50.00 is likely 50.
            
            // For now, let's just strip non-digits to be safe for PYG context where 50.000 is common.
            // But 50.50 might be 50.5.
            // If the string contains a separator:
            if (clean.contains('.') || clean.contains(',')) {
                // ... (Existing logic for separators)
                // Let's stick to the previous simple logic for now but fix the regex to capture the number.
                // The previous regex didn't capture "50000".
            }
            
            clean = raw.replaceAll(RegExp(r'[^0-9]'), '');
            double? val = double.tryParse(clean);
            if (val != null) {
                 val = val * multiplier;
                 if (val > maxVal) {
                    maxVal = val;
                 }
            }
        }
        if (maxVal > 0) {
            amount = maxVal;
        }
    }

    String lowerText = text.toLowerCase();

    // Detect Intent (Income vs Expense)
    bool? isIncome = _detectTransactionType(lowerText);

    // Heuristic Category Matching
    String? matchedCategory;
    
    // 1. Direct match with existing category names
    for (var cat in categories) {
        if (lowerText.contains(cat.name.toLowerCase())) {
            matchedCategory = cat.name;
            break; 
        }
    }
    
    // 2. Keyword mapping (Common PY context)
    matchedCategory ??= _heuristicMatch(lowerText);

    // If heuristic match detected Income (e.g. "devolvieron"), enforce isIncome=true
    if (matchedCategory == 'Ingresos') {
        isIncome = true;
    }
    
    // Account Matching
    String? matchedAccountId;
    for (var acc in accounts) {
        if (lowerText.contains(acc.name.toLowerCase())) {
            matchedAccountId = acc.id;
            break;
        } else {
            // Check for last word match (e.g. "Ueno" from "Banco Ueno")
            // Only if account name has multiple words
            final parts = acc.name.split(' ');
            if (parts.length > 1) {
                final distinctName = parts.last.toLowerCase();
                if (distinctName.length > 2 && lowerText.contains(distinctName)) {
                    matchedAccountId = acc.id;
                    break;
                }
            }
        }
    }

    // Extraction of suggested names if no match found
    String? suggestedCategory;
    String? suggestedAccount;

    if (matchedCategory == null) {
        // Regex to find "en [Category]"
        // Examples: "en el super", "en farmacia", "en juegos"
        final catRegex = RegExp(r'\b(?:en|concepto)\s+(?:el\s+|la\s+|los\s+|las\s+)?([a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ]+)\b', caseSensitive: false);
        final match = catRegex.firstMatch(text);
        if (match != null) {
            suggestedCategory = match.group(1);
            
            // Filter out common false positives for categories
            if (suggestedCategory != null) {
                final lowerCat = suggestedCategory.toLowerCase();
                if (lowerCat == 'mi' || lowerCat == 'mis' || lowerCat == 'tu' || lowerCat == 'tus' || lowerCat == 'su' || lowerCat == 'sus') {
                    suggestedCategory = null;
                }
            }

            // Capitalize
            if (suggestedCategory != null && suggestedCategory.isNotEmpty) {
                suggestedCategory = '${suggestedCategory[0].toUpperCase()}${suggestedCategory.substring(1).toLowerCase()}';
            }
        }
    }

    if (matchedAccountId == null) {
        // Regex to find "con [Account]", "desde [Account]", "de [Account]", "a mi [Account]", "en mi [Account]"
        // Examples: "con ueno", "desde itau", "de mi billetera", "a mi itau", "en mi itau"
        // Expanded to handle accents and "al/del"
        final accRegex = RegExp(r'\b(?:(?:con|desde|usando|via|de|del)\s+(?:el\s+|la\s+|mi\s+|mí\s+|mis\s+|mís\s+)?|(?:a|al|en)\s+(?:mi\s+|mí\s+|mis\s+|mís\s+|su\s+|sus\s+|tu\s+|tú\s+|tus\s+))([a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ]+)\b', caseSensitive: false);
        final match = accRegex.firstMatch(text);
        if (match != null) {
            suggestedAccount = match.group(1);
            
            // Avoid capturing same word as category if suggestedCategory matches
            if (suggestedCategory != null && suggestedAccount != null && suggestedAccount.toLowerCase() == suggestedCategory.toLowerCase()) {
                suggestedAccount = null;
            }
            
            // Capitalize
            if (suggestedAccount != null && suggestedAccount.isNotEmpty) {
                suggestedAccount = '${suggestedAccount[0].toUpperCase()}${suggestedAccount.substring(1).toLowerCase()}';
            }
        }
    }
    
    return NlpResult(
        amount: amount,
        currency: currency,
        date: date,
        matchedCategoryName: matchedCategory,
        matchedAccountId: matchedAccountId,
        suggestedCategoryName: suggestedCategory,
        suggestedAccountName: suggestedAccount,
        concept: text, // Use full text as concept for now
        isIncome: isIncome
    );
  }
  
  bool? _detectTransactionType(String text) {
      // Income keywords
      if (text.contains('ingreso') || 
          text.contains('recibi') || 
          text.contains('cobre') || 
          text.contains('gane') || 
          text.contains('deposito') || 
          text.contains('devolvieron') || 
          text.contains('devolucion') || 
          text.contains('reembolso')) {
          return true;
      }
      
      // Expense keywords
      if (text.contains('gaste') || 
          text.contains('pague') || 
          text.contains('compre') || 
          text.contains('sali') || 
          text.contains('perdi') || 
          text.contains('envie') || 
          text.contains('transferi')) {
          return false;
      }
      
      return null;
  }
  
  String? _heuristicMatch(String text) {
      // Income / Refund
      if (text.contains('devolvieron') || text.contains('devolucion') || text.contains('reembolso') || text.contains('recibi') || text.contains('ingreso') || text.contains('cobre')) return 'Ingresos';
      
      // Food / Supermarket
      if (text.contains('super') || text.contains('biggie') || text.contains('stock') || text.contains('superseis')) return 'Supermercado';
      if (text.contains('comida') || text.contains('cena') || text.contains('almuerzo') || text.contains('burger')) return 'Comida';
      
      // Transport
      if (text.contains('uber') || text.contains('bolt') || text.contains('nafta') || text.contains('combustible')) return 'Transporte';
      
      // Services
      if (text.contains('ande') || text.contains('essap') || text.contains('internet') || text.contains('tigo') || text.contains('personal')) return 'Servicios';
      
      // Health
      if (text.contains('farmacia') || text.contains('remedio') || text.contains('medico')) return 'Salud';
      
      return null;
  }
  
  Future<void> dispose() async {
      await _entityExtractor.close();
  }
}
