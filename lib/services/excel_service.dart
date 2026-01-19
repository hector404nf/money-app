import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';

class ExcelService {
  List<Transaction> parseExcel({
    required List<int> bytes,
    required List<Category> categories,
    required List<Account> accounts,
    required int selectedYear,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final newTransactions = <Transaction>[];

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
          if (typeStr.contains('INCOME')) {
            mainType = MainType.incomes;
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
          String accountId = _findAccountId(accounts, accountStr);

          // Status
          final statusStr = _getCellValue(row[statusColIdx!]?.value).toUpperCase();
          TransactionStatus status = TransactionStatus.pagado;
          if (statusStr != 'PAGADO') {
            status = TransactionStatus.pendiente;
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
    
    return newTransactions;
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

  String _findAccountId(List<Account> accounts, String name) {
    if (accounts.isEmpty) return 'default_acc_id';

    try {
      final existing = accounts.firstWhere(
        (a) => _normalize(a.name) == _normalize(name) || _normalize(a.type.displayName) == _normalize(name),
        orElse: () => accounts.first, 
      );
      return existing.id;
    } catch (e) {
      return accounts.first.id;
    }
  }

  String _normalize(String s) => s.toLowerCase().trim();
}
