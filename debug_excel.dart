import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final file = File('c:\\projects\\money_app\\importar.xlsx');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }

  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);

  for (var table in excel.tables.keys) {
    print('Sheet: $table');
    print('-------------------');
    final sheet = excel.tables[table];
    if (sheet == null) continue;
    
    // Print first 50 rows
    int count = 0;
    for (var row in sheet.rows) {
      if (count > 50) break;
      final rowData = row.map((cell) {
        if (cell == null) return 'null';
        if (cell is TextCellValue) return '"${cell.value}"';
        return cell.value.toString();
      }).toList();
      print('Row $count: $rowData');
      count++;
    }
    print('\n');
  }
}
