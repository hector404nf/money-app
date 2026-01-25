import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../models/account.dart'; // Keep for types if needed
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../services/excel_service.dart';

class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  bool _isLoading = false;
  String? _fileName;
  List<Transaction> _previewTransactions = [];
  List<Account> _newAccounts = [];
  int _selectedYear = DateTime.now().year;
  String? _error;
  final ExcelService _excelService = ExcelService();

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _previewTransactions = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.single;
        setState(() {
          _fileName = file.name;
        });

        await _parseExcel(file.bytes!);
      }
    } catch (e) {
      setState(() {
        _error = 'Error al leer el archivo: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _parseExcel(List<int> bytes) async {
    try {
      final provider = Provider.of<DataProvider>(context, listen: false);
      
      final result = _excelService.parseExcel(
        bytes: bytes,
        categories: provider.categories,
        accounts: provider.accounts,
        selectedYear: _selectedYear,
      );

      setState(() {
        _previewTransactions = result.transactions;
        _newAccounts = result.newAccounts;
        if (_previewTransactions.isEmpty) {
          _error = 'No se pudieron extraer transacciones. Verifique el formato.';
        }
      });

    } catch (e) {
      setState(() {
        _error = 'Error procesando Excel: $e';
      });
    }
  }

  Future<void> _import() async {
    if (_previewTransactions.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<DataProvider>(context, listen: false);
      
      // First, create new accounts if any
      int createdAccounts = 0;
      for (var acc in _newAccounts) {
        // Double check if it wasn't added in a previous run (though this is batch)
        if (!provider.accounts.any((a) => a.id == acc.id)) {
          provider.addAccountObject(acc);
          createdAccounts++;
        }
      }

      for (var t in _previewTransactions) {
        provider.addTransactionObject(t);
      }

      if (mounted) {
        final accMsg = createdAccounts > 0 ? ' y $createdAccounts cuentas' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importadas ${_previewTransactions.length} transacciones$accMsg exitosamente'),
            backgroundColor: AppColors.income,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Error guardando transacciones: $e';
        _isLoading = false;
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formato del Excel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El archivo Excel debe tener las siguientes columnas en la primera fila (o cerca):',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildBullet('MONTH: Número del mes (ej. 1, 2, 12)'),
              _buildBullet('MAIN TYPE: "Income" o "Expense"'),
              _buildBullet('CATEGORY: Categoría general'),
              _buildBullet('SUB-CATEGORY: Categoría específica (usada como categoría principal)'),
              _buildBullet('ACCOUNT: Nombre de la cuenta (Efectivo, Banco, etc.)'),
              _buildBullet('AMOUNT: Monto (número)'),
              _buildBullet('STATUS: "PAGADO" para confirmar, otro para pendiente'),
              const SizedBox(height: 16),
              const Text(
                'Nota: El sistema intentará buscar las cabeceras automáticamente.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Excel'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            color: theme.textTheme.bodyLarge?.color,
            onPressed: _showHelpDialog,
          ),
        ],
        titleTextStyle: theme.textTheme.titleLarge,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 16),
                        const Text('Año de los datos:'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: _selectedYear,
                          underline: const SizedBox(),
                          items: List.generate(5, (i) {
                            final year = DateTime.now().year - 2 + i;
                            return DropdownMenuItem(value: year, child: Text('$year'));
                          }),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedYear = v;
                                // Re-parse if file loaded
                                if (_fileName != null) {
                                  // We'd need to keep bytes in memory or re-read. 
                                  // For now just update year for future parses or reset.
                                  _previewTransactions = [];
                                  _fileName = null; 
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_fileName == null)
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Seleccionar Archivo Excel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    else
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.income),
              title: Text(_fileName!),
              subtitle: Text(
                '${_previewTransactions.length} movimientos found${_newAccounts.isNotEmpty ? ' • ${_newAccounts.length} new accounts' : ''}'
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _pickFile,
              ),
            ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.expense),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _previewTransactions.length,
                    itemBuilder: (context, index) {
                      final t = _previewTransactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.mainType == MainType.incomes 
                                ? AppColors.income.withOpacity(0.1) 
                                : AppColors.expense.withOpacity(0.1),
                            child: Icon(
                              t.mainType == MainType.incomes ? Icons.arrow_downward : Icons.arrow_upward,
                              color: t.mainType == MainType.incomes ? AppColors.income : AppColors.expense,
                              size: 16,
                            ),
                          ),
                          title: Text(t.notes ?? t.subCategory ?? 'Sin descripción'),
                          subtitle: Text('${t.date.day}/${t.date.month} • ${t.accountId}'),
                          trailing: Text(
                            AppColors.formatCurrency(t.amount),
                            style: TextStyle(
                              color: t.mainType == MainType.incomes ? AppColors.income : AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_previewTransactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _import,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Confirmar Importación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
