import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../providers/data_provider.dart';
import '../services/nlp_service.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/account.dart';

class AiInputScreen extends StatefulWidget {
  static const routeName = '/ai-input';

  const AiInputScreen({super.key});

  @override
  State<AiInputScreen> createState() => _AiInputScreenState();
}

class _AiInputScreenState extends State<AiInputScreen> {
  final _nlpService = NlpService();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  
  final _textController = TextEditingController();
  bool _isProcessing = false;
  
  // Parsed Data for Editing
  bool _showResult = false;
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  Account? _selectedAccount;
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
  bool? _detectedIsIncome;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    
    // Set default account if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<DataProvider>(context, listen: false);
        if (provider.accounts.isNotEmpty) {
            // Prefer 'Efectivo' or 'Cash' if exists
            try {
                _selectedAccount = provider.accounts.firstWhere(
                    (a) => a.name.toLowerCase().contains('efectivo') || a.name.toLowerCase().contains('cash')
                );
            } catch (_) {
                _selectedAccount = provider.accounts.first;
            }
            setState(() {});
        }
    });
  }
  
  Future<void> _initSpeech() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
        await Permission.microphone.request();
    }
    
    try {
      _speechAvailable = await _speech.initialize(
          onError: (e) => debugPrint('Speech Error: $e'),
          onStatus: (s) {
            debugPrint('Speech Status: $s');
            if (s == 'done' || s == 'notListening') {
                setState(() => _isListening = false);
            }
          },
      );
    } catch (e) {
      debugPrint('Speech Init Error: $e');
    }
    if (mounted) setState(() {});
  }

  void _listen() async {
      if (!_speechAvailable) {
          await _initSpeech();
          if (!mounted) return;
          if (!_speechAvailable) {
             ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Reconocimiento de voz no disponible'))
             );
             return;
          }
      }
      
      if (_isListening) {
          _speech.stop();
          setState(() => _isListening = false);
      } else {
          setState(() {
              _isListening = true;
              _textController.clear();
          });
          _speech.listen(
              onResult: (val) {
                  setState(() {
                      _textController.text = val.recognizedWords;
                  });
              },
              cancelOnError: true,
          );
      }
  }

  Future<void> _processText() async {
      if (_textController.text.isEmpty) return;
      
      setState(() {
        _isProcessing = true;
        _showResult = false;
      });
      
      try {
        final provider = Provider.of<DataProvider>(context, listen: false);
        final result = await _nlpService.processText(
            _textController.text, 
            provider.categories,
            provider.accounts
        );

        if (!mounted) return;
        
        setState(() {
            _isProcessing = false;
            _showResult = true;
            _detectedIsIncome = result.isIncome;
            
            // Populate fields
            if (result.amount != null) {
                _amountController.text = result.amount!.toStringAsFixed(0);
            }
            if (result.date != null) {
                _selectedDate = result.date!;
            }
            
            // Category Logic (Auto-create)
            String? targetCategoryName = result.matchedCategoryName ?? result.suggestedCategoryName;
            if (targetCategoryName != null) {
                try {
                    _selectedCategory = provider.categories.firstWhere(
                        (c) => c.name.toLowerCase() == targetCategoryName.toLowerCase()
                    );
                } catch (_) {
                     // Not found -> Create it
                     try {
                         // Determine kind based on name or detected intent
                         CategoryKind kind = CategoryKind.expense;
                         
                         if (result.isIncome == true) {
                            kind = CategoryKind.income;
                         } else if (result.isIncome == false) {
                            kind = CategoryKind.expense;
                         } else {
                             // Fallback to name-based check
                             final lowerName = targetCategoryName.toLowerCase();
                             if (lowerName.contains('ingreso') || 
                                 lowerName.contains('sueldo') || 
                                 lowerName.contains('salario') || 
                                 lowerName.contains('deposito') ||
                                 lowerName.contains('cobro') ||
                                 lowerName.contains('devolucion')) {
                                 kind = CategoryKind.income;
                             }
                         }

                         final newId = provider.addCategory(
                            name: targetCategoryName, 
                            kind: kind
                         );
                         _selectedCategory = provider.categories.firstWhere((c) => c.id == newId);
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Categoría creada: $targetCategoryName'))
                         );
                     } catch (e) {
                         debugPrint('Error creating category: $e');
                     }
                }
            }

            // Account Logic (Auto-create)
            if (result.matchedAccountId != null) {
                try {
                    _selectedAccount = provider.accounts.firstWhere(
                        (a) => a.id == result.matchedAccountId
                    );
                } catch (_) {}
            } else if (result.suggestedAccountName != null) {
                 final suggestedAccountName = result.suggestedAccountName!;
                 try {
                    _selectedAccount = provider.accounts.firstWhere(
                        (a) => a.name.toLowerCase() == suggestedAccountName.toLowerCase()
                    );
                 } catch (_) {
                    // Create it
                    try {
                        final newId = provider.addAccount(
                            name: suggestedAccountName,
                            type: AccountType.bank,
                            initialBalance: 0
                        );
                        _selectedAccount = provider.accounts.firstWhere((a) => a.id == newId);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Cuenta creada: $suggestedAccountName'))
                        );
                    } catch (e) {
                        debugPrint('Error creating account: $e');
                    }
                 }
            }
            
            // Use original text as note if concept is missing, or specific concept
            _noteController.text = _textController.text;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar: $e')));
      }
  }
  
  void _saveTransaction() {
      if (_amountController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El monto es requerido'))
          );
          return;
      }
      if (_selectedCategory == null) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La categoría es requerida'))
          );
          return;
      }
      if (_selectedAccount == null) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La cuenta es requerida'))
          );
          return;
      }
      
      final amount = double.tryParse(_amountController.text.replaceAll(',', '').replaceAll('.', ''));
      if (amount == null) return;
      
      // Handle Expense vs Income logic based on Category Kind or Name or Detected Intent
      double finalAmount = amount;
      bool isIncome = _selectedCategory!.kind == CategoryKind.income;
      
      // Safety check: if category name implies income, force it as income
      final lowerCatName = _selectedCategory!.name.toLowerCase();
      if (lowerCatName.contains('ingreso') || lowerCatName.contains('sueldo') || lowerCatName.contains('devolucion')) {
          isIncome = true;
      }
      
      // Override if NLP explicitly detected income/expense
      if (_detectedIsIncome != null) {
          isIncome = _detectedIsIncome!;
      }

      if (!isIncome && (_selectedCategory!.kind == CategoryKind.expense || _selectedCategory!.kind == CategoryKind.debt)) {
          finalAmount = -amount.abs();
      } else {
          finalAmount = amount.abs();
      }
      
      final t = model.Transaction(
          id: const Uuid().v4(),
          date: _selectedDate,
          monthKey: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}',
          mainType: isIncome ? model.MainType.incomes : model.MainType.expenses,
          categoryId: _selectedCategory!.id,
          accountId: _selectedAccount!.id,
          amount: finalAmount,
          status: model.TransactionStatus.pagado, // Assume paid if entering manually via voice
          notes: _noteController.text,
      );
      
      Provider.of<DataProvider>(context, listen: false).addTransactionObject(t);
      
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción guardada exitosamente'))
      );
      Navigator.pop(context);
  }

  @override
  void dispose() {
      _nlpService.dispose();
      _textController.dispose();
      _amountController.dispose();
      _noteController.dispose();
      super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<DataProvider>(context).categories;
    final accounts = Provider.of<DataProvider>(context).accounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA (Beta)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Voice Input Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Dí algo como: "Gasté 50 mil en Superseis"'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe aquí (ej. "Gasté 50 mil en super") o usa el micrófono...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          onPressed: _listen,
                          backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
                          child: Icon(_isListening ? Icons.stop : Icons.mic),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _processText,
                          icon: _isProcessing 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : const Icon(Icons.auto_awesome),
                          label: const Text('Procesar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Result Section
            if (_showResult) ...[
              const Text('Datos Detectados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Amount
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      
                      // Category
                      DropdownButtonFormField<Category>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                      const SizedBox(height: 12),
                      
                      // Account
                      DropdownButtonFormField<Account>(
                        value: _selectedAccount,
                        decoration: const InputDecoration(
                          labelText: 'Cuenta',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: accounts.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedAccount = val),
                      ),
                      const SizedBox(height: 12),
                      
                      // Date
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text('Fecha: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                        onTap: () async {
                           final picked = await showDatePicker(
                             context: context, 
                             initialDate: _selectedDate, 
                             firstDate: DateTime(2000), 
                             lastDate: DateTime(2100)
                           );
                           if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                      
                      // Note
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Nota',
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('CONFIRMAR Y GUARDAR'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
