import 'package:flutter_test/flutter_test.dart';
import 'package:money_app/models/account.dart';
import 'package:money_app/models/category.dart';
import 'package:money_app/models/transaction.dart';
import 'package:money_app/services/excel_service.dart';
import 'package:excel/excel.dart';

void main() {
  late ExcelService excelService;
  late List<Category> mockCategories;
  late List<Account> mockAccounts;

  setUp(() {
    excelService = ExcelService();
    mockCategories = [
      Category(id: 'cat1', name: 'Food', kind: CategoryKind.expense),
      Category(id: 'cat2', name: 'Salary', kind: CategoryKind.income),
      Category(id: 'cat3', name: 'Varios', kind: CategoryKind.expense),
    ];
    mockAccounts = [
      Account(id: 'acc1', name: 'Cash', type: AccountType.cash, initialBalance: 0),
      Account(id: 'acc2', name: 'Bank', type: AccountType.bank, initialBalance: 0),
    ];
  });

  test('parseExcel parses valid data correctly', () {
    // Create an Excel file in memory
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Add headers
    List<CellValue> headers = [
      TextCellValue('MONTH'), 
      TextCellValue('MAIN TYPE'), 
      TextCellValue('CATEGORY'), 
      TextCellValue('SUB-CATEGORY'), 
      TextCellValue('ACCOUNT'), 
      TextCellValue('AMOUNT'), 
      TextCellValue('STATUS')
    ];
    sheetObject.appendRow(headers);

    // Add a row
    // Month: 5 (May)
    // Type: Expense
    // Cat: General
    // SubCat: Food
    // Account: Cash
    // Amount: 50000
    // Status: PAGADO
    sheetObject.appendRow([
      IntCellValue(5), 
      TextCellValue('Expense'), 
      TextCellValue('General'), 
      TextCellValue('Food'), 
      TextCellValue('Cash'), 
      IntCellValue(50000), 
      TextCellValue('PAGADO')
    ]);

    var bytes = excel.encode();
    
    final result = excelService.parseExcel(
      bytes: bytes!,
      categories: mockCategories,
      accounts: mockAccounts,
      selectedYear: 2023,
    );

    expect(result.transactions.length, 1);
    final t = result.transactions.first;
    expect(t.date.year, 2023);
    expect(t.date.month, 5);
    expect(t.amount, -50000.0);
    expect(t.categoryId, 'cat1'); // Should match 'Food' because subcategory is 'Food'
    expect(t.accountId, 'acc1'); // Should match 'Cash'
    expect(t.mainType, MainType.expenses);
    expect(t.status, TransactionStatus.pagado);
  });

  test('parseExcel handles missing columns gracefully', () {
    // Create an Excel file with missing headers
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Missing AMOUNT
    List<CellValue> headers = [
      TextCellValue('MONTH'), 
      TextCellValue('MAIN TYPE')
    ];
    sheetObject.appendRow(headers);
    sheetObject.appendRow([IntCellValue(5), TextCellValue('Expense')]);

    var bytes = excel.encode();
    
    final result = excelService.parseExcel(
      bytes: bytes!,
      categories: mockCategories,
      accounts: mockAccounts,
      selectedYear: 2023,
    );

    expect(result.transactions.isEmpty, true);
  });

  test('parseExcel handles negative amounts for expenses correctly', () {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Add headers
    List<CellValue> headers = [
      TextCellValue('MONTH'), 
      TextCellValue('MAIN TYPE'), 
      TextCellValue('CATEGORY'), 
      TextCellValue('SUB-CATEGORY'), 
      TextCellValue('ACCOUNT'), 
      TextCellValue('AMOUNT'), 
      TextCellValue('STATUS')
    ];
    sheetObject.appendRow(headers);

    // Add a row with negative expense
    sheetObject.appendRow([
      IntCellValue(5), 
      TextCellValue('Expense'), 
      TextCellValue('General'), 
      TextCellValue('Food'), 
      TextCellValue('Cash'), 
      IntCellValue(-20000), // Negative amount
      TextCellValue('PAGADO')
    ]);

    var bytes = excel.encode();
    
    final result = excelService.parseExcel(
      bytes: bytes!,
      categories: mockCategories,
      accounts: mockAccounts,
      selectedYear: 2023,
    );

    expect(result.transactions.length, 1);
    final t = result.transactions.first;
    expect(t.amount, -20000.0); // Should be negative for expense
    expect(t.mainType, MainType.expenses);
  });

  test('parseExcel handles fuzzy account matching', () {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Add headers
    List<CellValue> headers = [
      TextCellValue('MONTH'), 
      TextCellValue('MAIN TYPE'), 
      TextCellValue('CATEGORY'), 
      TextCellValue('SUB-CATEGORY'), 
      TextCellValue('ACCOUNT'), 
      TextCellValue('AMOUNT'), 
      TextCellValue('STATUS')
    ];
    sheetObject.appendRow(headers);

    // Add rows with tricky account names
    sheetObject.appendRow([IntCellValue(1), TextCellValue('Expense'), TextCellValue('Cat'), TextCellValue('Sub'), TextCellValue('UENO'), IntCellValue(100), TextCellValue('PAGADO')]);
    sheetObject.appendRow([IntCellValue(1), TextCellValue('Expense'), TextCellValue('Cat'), TextCellValue('Sub'), TextCellValue('CASH'), IntCellValue(100), TextCellValue('PAGADO')]);
    
    // Create accounts with slightly different names
    final fuzzyAccounts = [
       Account(id: 'ueno_id', name: 'Ueno Bank', type: AccountType.bank, initialBalance: 0),
       Account(id: 'cash_id', name: 'Efectivo', type: AccountType.cash, initialBalance: 0),
    ];

    var bytes = excel.encode();
    
    final result = excelService.parseExcel(
      bytes: bytes!,
      categories: mockCategories,
      accounts: fuzzyAccounts,
      selectedYear: 2023,
    );

    expect(result.transactions.length, 2);
    // UENO should match Ueno Bank
    expect(result.transactions[0].accountId, 'ueno_id');
    // CASH should match Efectivo
    expect(result.transactions[1].accountId, 'cash_id');
  });

  test('parseExcel defaults to PENDIENTE for empty status', () {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Add headers
    List<CellValue> headers = [
      TextCellValue('MONTH'), 
      TextCellValue('MAIN TYPE'), 
      TextCellValue('CATEGORY'), 
      TextCellValue('SUB-CATEGORY'), 
      TextCellValue('ACCOUNT'), 
      TextCellValue('AMOUNT'), 
      TextCellValue('STATUS')
    ];
    sheetObject.appendRow(headers);

    // Empty status
    sheetObject.appendRow([IntCellValue(1), TextCellValue('Expense'), TextCellValue('Cat'), TextCellValue('Sub'), TextCellValue('Acc'), IntCellValue(100), null]);

    var bytes = excel.encode();
    
    final result = excelService.parseExcel(
      bytes: bytes!,
      categories: mockCategories,
      accounts: mockAccounts,
      selectedYear: 2023,
    );

    expect(result.transactions.length, 1);
    expect(result.transactions.first.status, TransactionStatus.pendiente);
  });
}
