import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/debt.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debtToEdit;

  const AddDebtScreen({super.key, this.debtToEdit});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  
  late DebtType _type;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.debtToEdit != null) {
      final debt = widget.debtToEdit!;
      _nameController.text = debt.name;
      _amountController.text = debt.totalAmount.toString();
      if (debt.interestRate != null) {
        _interestRateController.text = debt.interestRate.toString();
      }
      _type = debt.type;
      _startDate = debt.startDate;
      _endDate = debt.endDate;
      _selectedAccountId = debt.accountId;
    } else {
      _type = DebtType.lending; // Default: Me deben
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : (_endDate ?? DateTime.now());
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      
      final name = _nameController.text.trim();
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final interestRate = _interestRateController.text.isNotEmpty 
          ? double.tryParse(_interestRateController.text.replaceAll(',', '.')) 
          : null;

      if (widget.debtToEdit != null) {
        // Edit existing
        final updatedDebt = widget.debtToEdit!.copyWith(
          name: name,
          type: _type,
          totalAmount: amount,
          // If amount changed, we might need to adjust remaining amount logic.
          // For simplicity, if total amount changes, we adjust remaining amount by the difference
          // OR we just reset remaining amount if it's a new logic.
          // Let's assume user edits the total amount, we preserve paid amount (total - remaining).
          remainingAmount: amount - (widget.debtToEdit!.totalAmount - widget.debtToEdit!.remainingAmount),
          interestRate: interestRate,
          startDate: _startDate,
          endDate: _endDate,
          accountId: _selectedAccountId,
        );
        provider.updateDebt(updatedDebt);
      } else {
        // Create new
        final newDebt = Debt(
          id: const Uuid().v4(),
          name: name,
          type: _type,
          totalAmount: amount,
          remainingAmount: amount, // Initially full amount is remaining
          interestRate: interestRate,
          startDate: _startDate,
          endDate: _endDate,
          accountId: _selectedAccountId,
        );
        provider.addDebt(newDebt);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DataProvider>(context);
    final accounts = provider.accounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debtToEdit != null ? 'Editar Deuda' : 'Nueva Deuda'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.iconTheme.color),
        actions: [
          if (widget.debtToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar deuda'),
                    content: const Text('¿Estás seguro de que quieres eliminar esta deuda?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.deleteDebt(widget.debtToEdit!.id);
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close screen
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector
              Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = DebtType.lending),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == DebtType.lending ? Colors.green.withOpacity(0.2) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: _type == DebtType.lending ? Border.all(color: Colors.green) : null,
                          ),
                          child: Center(
                            child: Text(
                              'Me deben',
                              style: TextStyle(
                                color: _type == DebtType.lending ? Colors.green : theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = DebtType.borrowing),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == DebtType.borrowing ? Colors.red.withOpacity(0.2) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: _type == DebtType.borrowing ? Border.all(color: Colors.red) : null,
                          ),
                          child: Center(
                            child: Text(
                              'Debo',
                              style: TextStyle(
                                color: _type == DebtType.borrowing ? Colors.red : theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre / Descripción',
                  hintText: 'Ej: Préstamo Auto, Juan Pérez',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto Total',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un monto';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest Rate (Optional)
              TextFormField(
                controller: _interestRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tasa de Interés % (Opcional)',
                  hintText: 'Ej: 5.0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.percent),
                ),
              ),
              const SizedBox(height: 16),

              // Account Selector (Optional)
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: 'Cuenta Relacionada (Opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Ninguna'),
                  ),
                  ...accounts.map((account) {
                    return DropdownMenuItem<String>(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha Inicio',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha Vencimiento',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.event_available),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Sin fecha',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Guardar Deuda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
