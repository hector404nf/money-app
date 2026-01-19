import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';

class ExcelParseResult {
  final List<Transaction> transactions;
  final List<Account> newAccounts;

  ExcelParseResult({
    required this.transactions,
    required this.newAccounts,
  });
}

class ExcelService {
  ExcelParseResult parseExcel({
    required List<int> bytes,
    required List<Category> categories,
    required List<Account> accounts,
    required int selectedYear,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final newTransactions = <Transaction>[];
    final newAccounts = <Account>[];
    
    // Mutable map to track accounts during this parse session
    final accountMap = <String, Account>{}; // normalizedName -> Account
    
    // Populate with existing accounts
    for (var acc in accounts) {
      accountMap[_normalize(acc.name)] = acc;
    }

    // Assuming the first sheet has the data
    if (excel.tables.isEmpty) {
      throw Exception('El archivo Excel está vacío.');
    }
    
    final table = excel.tables[excel.tables.keys.first];

    if (table == null) {
      throw Exception('No se encontraron datos en el archivo');
    }

    // Find header row to map columns
    int? monthColIdx;
    int? mainTypeColIdx;
    int? categoryColIdx;
    int? subCategoryColIdx;
    int? accountColIdx;
    int? amountColIdx;
    int? statusColIdx;

    // Iterate rows to find headers and data
    bool headersFound = false;

    for (var row in table.rows) {
      if (row.isEmpty) continue;

      // Try to identify headers
      if (!headersFound) {
        for (int i = 0; i < row.length; i++) {
          final cellValue = _getCellValue(row[i]?.value).toUpperCase();
          if (cellValue == 'MONTH') monthColIdx = i;
          if (cellValue == 'MAIN TYPE') mainTypeColIdx = i;
          if (cellValue == 'CATEGORY') categoryColIdx = i;
          if (cellValue == 'SUB-CATEGORY') subCategoryColIdx = i;
          if (cellValue == 'ACCOUNT') accountColIdx = i;
          if (cellValue == 'AMOUNT') amountColIdx = i;
          if (cellValue == 'STATUS') statusColIdx = i;
        }

        if (monthColIdx != null && amountColIdx != null) {
          headersFound = true;
          continue; // Skip header row
        }
      }

      if (headersFound) {
        // Parse data row
        try {
          final monthVal = row[monthColIdx!]?.value;
          final amountVal = row[amountColIdx!]?.value;

          if (monthVal == null || amountVal == null) continue;

          // Parse Month
          int month = 1;
          if (monthVal is IntCellValue) {
            month = monthVal.value;
          } else {
            String s = _getCellValue(monthVal);
            month = int.tryParse(s) ?? 1;
          }

          // Parse Date (Assume 1st of month + selected Year)
          final date = DateTime(selectedYear, month, 1);
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

          // Parse Amount
          double amount = 0.0;
          if (amountVal is IntCellValue) {
            amount = amountVal.value.toDouble();
          } else if (amountVal is DoubleCellValue) {
            amount = amountVal.value;
          } else {
             String s = _getCellValue(amountVal);
             // cleanup
             s = s.replaceAll('Gs', '').replaceAll('₲', '').trim().replaceAll(',', '');
             amount = double.tryParse(s) ?? 0.0;
          }
          
          // Parse Type
          MainType mainType = MainType.expenses;
          final typeStr = _getCellValue(row[mainTypeColIdx!]?.value).toUpperCase();
          if (typeStr.contains('INCOME') || typeStr.contains('INGRESO')) {
            mainType = MainType.incomes;
          }

          // Ensure amount sign matches type
          amount = amount.abs();
          if (mainType == MainType.expenses) {
            amount = -amount;
          }

          // Parse Category & SubCategory
          final catStr = _getCellValue(row[categoryColIdx!]?.value).trim();
          final subCatStr = _getCellValue(row[subCategoryColIdx!]?.value).trim();

          // Logic: subCategory is often the real category in this excel
          String targetCategoryName = subCatStr.isNotEmpty ? subCatStr : catStr;
          if (targetCategoryName.isEmpty) targetCategoryName = 'Varios';

          // Find or map Category
          String categoryId = _findCategoryId(categories, targetCategoryName, mainType);
          
          // Account
          final accountStr = _getCellValue(row[accountColIdx!]?.value).trim();
          
          // Find or Create Account
          Account? account;
          if (accountStr.isEmpty) {
            // Default logic if no account provided?
            // Ideally we shouldn't fail, but maybe default to "Default Account"
            // For now, let's try to find "Efectivo" or similar in map, or create one
            // We'll skip if empty? No, transaction needs account.
             // We'll use "Efectivo" as default name if empty
             final defaultName = 'Efectivo';
             account = _findOrCreateAccount(defaultName, accountMap, newAccounts);
          } else {
             account = _findOrCreateAccount(accountStr, accountMap, newAccounts);
          }
          String accountId = account.id;

          // Status
          final statusStr = _getCellValue(row[statusColIdx!]?.value).toUpperCase();
          TransactionStatus status = TransactionStatus.pendiente; // Default to PENDIENTE if empty
          
          if (statusStr.contains('PAGADO')) {
            status = TransactionStatus.pagado;
          } else if (statusStr.contains('PROGRAMADO')) {
            status = TransactionStatus.programado;
          }

          final t = Transaction(
            id: const Uuid().v4(),
            date: date,
            monthKey: monthKey,
            mainType: mainType,
            categoryId: categoryId,
            accountId: accountId,
            amount: amount,
            status: status,
            notes: catStr != targetCategoryName ? catStr : null, // Store Payee as note
            subCategory: subCatStr,
          );
          newTransactions.add(t);

        } catch (e) {
          print('Error parsing row: $e');
          // Continue to next row
        }
      }
    }
    
    return ExcelParseResult(
      transactions: newTransactions,
      newAccounts: newAccounts,
    );
  }

  Account _findOrCreateAccount(
    String name, 
    Map<String, Account> accountMap, 
    List<Account> newAccounts
  ) {
    final normalized = _normalize(name);
    
    // 1. Exact/Existing match in map
    if (accountMap.containsKey(normalized)) {
      return accountMap[normalized]!;
    }
    
    // 2. Fuzzy/Alias match against map keys
    // We iterate map values because map keys are normalized names, but aliases logic is complex
    // Reuse _findAccountId logic but adapted for map values
    final existing = _findAccountInMap(accountMap.values.toList(), name);
    if (existing != null) {
      accountMap[normalized] = existing; // Cache for next time
      return existing;
    }
    
    // 3. Create New
    final newAccount = Account(
      id: const Uuid().v4(),
      name: name, // Use original name
      type: AccountType.other, // Default type
      initialBalance: 0,
    );
    
    accountMap[normalized] = newAccount;
    newAccounts.add(newAccount);
    return newAccount;
  }
  
  Account? _findAccountInMap(List<Account> accounts, String name) {
    if (accounts.isEmpty) return null;
    final normalizedName = _normalize(name);
    
    // Common aliases map (Excel Name -> App Name keywords)
    final aliases = {
      'cash': ['efectivo', 'cash', 'físico'],
      'money': ['efectivo', 'cash'],
      'banco': ['bank', 'banco'],
      'itau': ['itau'],
      'ueno': ['ueno'],
      'coopeduc': ['coopeduc'],
      'vision': ['vision'],
    };

    try {
      return accounts.firstWhere((a) {
        final accName = _normalize(a.name);
        
        // 1. Exact match (already checked by map key, but safe to double check)
        if (accName == normalizedName) return true;
        
        // 2. Contains match
        if (accName.contains(normalizedName) || normalizedName.contains(accName)) return true;
        
        // 3. Alias match
        for (var entry in aliases.entries) {
          if (normalizedName.contains(entry.key)) {
             for (var val in entry.value) {
               if (accName.contains(val)) return true;
             }
          }
        }
        return false;
      });
    } catch (e) {
      return null;
    }
  }

  String _getCellValue(CellValue? cellValue) {
    if (cellValue == null) return '';
    if (cellValue is TextCellValue) {
      return cellValue.value.toString();
    } else if (cellValue is IntCellValue) {
      return cellValue.value.toString();
    } else if (cellValue is DoubleCellValue) {
      return cellValue.value.toString();
    } else if (cellValue is DateCellValue) {
      return cellValue.year.toString(); // Fallback
    }
    return cellValue.toString();
  }

  String _findCategoryId(List<Category> categories, String name, MainType type) {
    // Try exact match
    if (categories.isEmpty) return 'default_cat_id'; // Fallback if no categories
    
    try {
      final existing = categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
        orElse: () => categories.firstWhere(
          (c) => c.name.toLowerCase() == 'otros' || c.name.toLowerCase() == 'varios',
          orElse: () => categories.first,
        ),
      );
      return existing.id;
    } catch (e) {
      return categories.first.id;
    }
  }

  String _normalize(String s) => s.toLowerCase().trim();
}
