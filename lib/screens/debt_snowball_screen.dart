import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/ui_provider.dart';
import '../utils/constants.dart';

class DebtItem {
  String name;
  double balance;
  double rate; // Annual interest rate %
  double minPayment;

  DebtItem({
    required this.name,
    required this.balance,
    required this.rate,
    required this.minPayment,
  });
}

class DebtSnowballScreen extends StatefulWidget {
  const DebtSnowballScreen({super.key});

  @override
  State<DebtSnowballScreen> createState() => _DebtSnowballScreenState();
}

class _DebtSnowballScreenState extends State<DebtSnowballScreen> {
  final List<DebtItem> _debts = [];
  final _extraPaymentController = TextEditingController(text: '0');
  
  // Controllers for adding new debt
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _rateController = TextEditingController();
  final _minPaymentController = TextEditingController();

  Map<String, dynamic>? _simulationResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ui = Provider.of<UiProvider>(context, listen: false);
      final data = Provider.of<DataProvider>(context, listen: false);
      
      ui.markVisitedDebtSnowball();
      data.unlockAchievement('debt_snowball');
    });
  }

  void _addDebt() {
    final name = _nameController.text;
    final balance = double.tryParse(_balanceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final rate = double.tryParse(_rateController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final minPayment = double.tryParse(_minPaymentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

    if (name.isNotEmpty && balance > 0) {
      setState(() {
        _debts.add(DebtItem(name: name, balance: balance, rate: rate, minPayment: minPayment));
        _simulationResult = null; // Reset simulation
      });
      _nameController.clear();
      _balanceController.clear();
      _rateController.clear();
      _minPaymentController.clear();
      Navigator.pop(context); // Close dialog
    }
  }

  void _showAddDebtDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Deuda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Nombre (ej. Tarjeta Visa)'),
                textCapitalization: TextCapitalization.sentences,
              ),
              TextField(
                controller: _balanceController, 
                decoration: const InputDecoration(labelText: 'Saldo Pendiente', prefixText: 'Gs. '), 
                keyboardType: TextInputType.numberWithOptions(decimal: true)
              ),
              TextField(
                controller: _rateController, 
                decoration: const InputDecoration(labelText: 'Tasa Anual (%)', suffixText: '%'), 
                keyboardType: TextInputType.numberWithOptions(decimal: true)
              ),
              TextField(
                controller: _minPaymentController, 
                decoration: const InputDecoration(labelText: 'Pago Mínimo Mensual', prefixText: 'Gs. '), 
                keyboardType: TextInputType.numberWithOptions(decimal: true)
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: _addDebt, child: const Text('Agregar')),
        ],
      ),
    );
  }

  void _simulate() {
    if (_debts.isEmpty) return;

    final extraPayment = double.tryParse(_extraPaymentController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    
    // Sort debts for Snowball (Lowest balance first)
    final snowballDebts = List<DebtItem>.from(_debts)..sort((a, b) => a.balance.compareTo(b.balance));

    final snowballResult = _calculatePayoff(snowballDebts, extraPayment);

    setState(() {
      _simulationResult = snowballResult;
    });
  }

  Map<String, dynamic> _calculatePayoff(List<DebtItem> debts, double extraMonthly) {
    // Total Monthly Budget = Sum(All Min Payments) + Extra
    double totalBudget = debts.fold(0.0, (sum, d) => sum + d.minPayment) + extraMonthly;
    
    // Reset clones
    final simDebts = debts.map((d) => _SimDebt(d.name, d.balance, d.rate, d.minPayment)).toList();
    
    int simMonths = 0;
    double simTotalInterest = 0;
    
    while (simDebts.any((d) => d.balance > 0.1)) {
      simMonths++;
      if (simMonths > 1200) break; // Safety break (100 years)

      double moneyLeft = totalBudget;

      // 1. Accrue Interest
      for (var d in simDebts) {
        if (d.balance > 0) {
          double interest = d.balance * (d.rate / 100 / 12);
          d.balance += interest;
          simTotalInterest += interest;
        }
      }

      // 2. Pay Minimums
      for (var d in simDebts) {
        if (d.balance > 0) {
          double payment = d.minPayment;
          if (d.balance < payment) {
            payment = d.balance;
          }
          d.balance -= payment;
          moneyLeft -= payment;
        }
      }

      // 3. Pay Extra (Snowball) to the first active debt (sorted list)
      for (var d in simDebts) {
        if (moneyLeft <= 0.01) break;
        if (d.balance > 0) {
          double payment = moneyLeft;
          if (d.balance < payment) {
            payment = d.balance;
          }
          d.balance -= payment;
          moneyLeft -= payment;
        }
      }
    }

    return {
      'months': simMonths,
      'totalInterest': simTotalInterest,
      'debtFreeDate': DateTime.now().add(Duration(days: simMonths * 30)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bola de Nieve (Deudas)'),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDebtDialog,
        label: const Text('Agregar Deuda'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.expense,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro
            Text(
              'Elimina tus deudas más rápido',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'El método "Bola de Nieve" sugiere pagar primero la deuda más pequeña para ganar impulso.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Extra Payment Input
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('¿Cuánto extra puedes pagar al mes?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _extraPaymentController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixText: 'Gs. ',
                      ),
                      onChanged: (_) {
                         if (_simulationResult != null) _simulate();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Debt List
            if (_debts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No has agregado deudas aún.\nUsa el botón para comenzar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _debts.length,
                itemBuilder: (context, index) {
                  final debt = _debts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.expense.withOpacity(0.1),
                        child: Text('${index + 1}', style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(debt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${debt.rate}% interés anual'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppColors.formatCurrency(debt.balance), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense)),
                          Text('Min: ${AppColors.formatCurrency(debt.minPayment)}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      onLongPress: () {
                        setState(() {
                          _debts.removeAt(index);
                          _simulationResult = null;
                        });
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _simulate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CALCULAR PLAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],

            // Results
            if (_simulationResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  children: [
                    const Text('¡Libre de Deudas en!', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${_simulationResult!['months']} Meses',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Text(
                      '(${DateFormat('MMMM yyyy', 'es_ES').format(_simulationResult!['debtFreeDate'])})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Intereses Totales a Pagar:'),
                        Text(
                          AppColors.formatCurrency(_simulationResult!['totalInterest']),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}

class _SimDebt {
  String name;
  double balance;
  double rate;
  double minPayment;

  _SimDebt(this.name, this.balance, this.rate, this.minPayment);
}
