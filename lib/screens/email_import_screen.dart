import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/email_transaction_candidate.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/data_provider.dart';
import '../services/email_import_service.dart';
import '../utils/constants.dart';
import 'email_templates_screen.dart';

class EmailImportScreen extends StatefulWidget {
  const EmailImportScreen({super.key});

  @override
  State<EmailImportScreen> createState() => _EmailImportScreenState();
}

class _EmailImportScreenState extends State<EmailImportScreen> {
  final EmailImportService _service = EmailImportService();
  bool _isLoading = true;
  String? _error;
  List<EmailTransactionCandidate> _candidates = [];
  final Map<String, String?> _selectedAccountByMessage = {};
  final Map<String, String?> _selectedCategoryByMessage = {};

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    final provider = Provider.of<DataProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
      _error = null;
      _candidates = [];
      _selectedAccountByMessage.clear();
      _selectedCategoryByMessage.clear();
    });

    try {
      final since = DateTime.now().subtract(const Duration(days: 30));
      final result = await _service.fetchCandidates(
        since: since,
        templates: provider.emailTemplates,
      );
      if (!mounted) return;
      setState(() {
        _candidates = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importSelected() async {
    final provider = Provider.of<DataProvider>(context, listen: false);

    int created = 0;
    for (final c in _candidates) {
      final accountId = _selectedAccountByMessage[c.messageId];
      final categoryId = _selectedCategoryByMessage[c.messageId];
      if (accountId == null || categoryId == null) {
        continue;
      }

      final mainType = c.amount < 0 ? MainType.expenses : MainType.incomes;

      provider.addTransaction(
        amount: c.amount,
        categoryId: categoryId,
        accountId: accountId,
        date: c.date,
        notes: c.description,
        mainType: mainType,
      );
      created += 1;
    }

    if (!mounted) return;

    if (created == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un movimiento para importar')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Se importaron $created movimientos desde el correo')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar desde correo'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurar plantillas',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmailTemplatesScreen()),
              );
              // Refresh candidates with new templates
              _loadCandidates();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.blueGrey.shade700 : Colors.blue.shade100,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Búsqueda en tu Gmail',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Leemos los últimos correos de movimientos bancarios para ayudarte a crear transacciones. Revisa y confirma antes de guardar.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildBodyContent(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading || _candidates.isEmpty ? null : _importSelected,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Crear movimientos seleccionados'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Ocurrió un error al leer tus correos',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadCandidates,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_candidates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No se encontraron correos recientes con movimientos bancarios. Verifica que tu banco envíe notificaciones y vuelve a intentarlo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final provider = Provider.of<DataProvider>(context);
    final accounts = provider.accounts;
    final categories = provider.categories.where((c) => c.kind == CategoryKind.expense || c.kind == CategoryKind.income).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      itemCount: _candidates.length,
      itemBuilder: (context, index) {
        final c = _candidates[index];
        final accountId = _selectedAccountByMessage[c.messageId];
        final categoryId = _selectedCategoryByMessage[c.messageId];

        final amountColor = c.amount < 0 ? AppColors.expense : AppColors.income;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.bankName.isEmpty ? 'Movimiento detectado' : c.bankName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '${c.amount < 0 ? '-' : '+'} ${c.amount.abs().toStringAsFixed(0)} ${c.currency}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: accountId,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountByMessage[c.messageId] = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                        ),
                        items: categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryByMessage[c.messageId] = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

