import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../models/transaction.dart';

class PurchaseSimulatorScreen extends StatefulWidget {
  const PurchaseSimulatorScreen({super.key});

  @override
  State<PurchaseSimulatorScreen> createState() => _PurchaseSimulatorScreenState();
}

class _PurchaseSimulatorScreenState extends State<PurchaseSimulatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  
  double? _monthlySavingsAvg;
  double? _totalBalance;
  
  String? _resultMessage;
  Color? _resultColor;
  IconData? _resultIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateStats();
    });
  }

  void _calculateStats() {
    final provider = Provider.of<DataProvider>(context, listen: false);
    
    // 1. Calculate Total Balance (Cash available)
    double totalBalance = 0;
    for (var account in provider.accounts) {
      totalBalance += provider.getAccountBalance(account.id);
    }
    // Also include goals acting as accounts if any? 
    // DataProvider.getAccountBalance handles goals if passed by ID, but we iterate accounts list.
    // If goals are used as accounts, they might not be in accounts list unless we add them.
    // For now, let's stick to 'accounts'.

    // 2. Calculate Average Monthly Savings (Last 3 months)
    final now = DateTime.now();
    double totalSavings = 0;
    int monthsCounted = 0;

    for (int i = 1; i <= 3; i++) {
      final pastDate = DateTime(now.year, now.month - i, 1);
      final monthKey = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}';
      
      final income = provider.getIncomes(monthKey: monthKey);
      final expense = provider.getRealExpenses(monthKey: monthKey); // Returns positive number
      final savings = income - expense;
      
      // Only count if there was activity
      if (income > 0 || expense > 0) {
        totalSavings += savings;
        monthsCounted++;
      }
    }

    double avgSavings = monthsCounted > 0 ? totalSavings / monthsCounted : 0;

    setState(() {
      _totalBalance = totalBalance;
      _monthlySavingsAvg = avgSavings;
    });
  }

  void _simulate() {
    if (!_formKey.currentState!.validate()) return;
    if (_totalBalance == null || _monthlySavingsAvg == null) return;

    final price = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    
    if (price <= 0) return;

    // Logic for recommendation
    // Scenario 1: Can pay with cash now
    if (_totalBalance! >= price) {
      // Check impact on savings
      final remaining = _totalBalance! - price;
      final percentage = (price / _totalBalance!) * 100;
      
      if (percentage < 20) {
        // Safe buy
        setState(() {
          _resultColor = Colors.green;
          _resultIcon = Icons.check_circle_outline;
          _resultMessage = '¡Puedes comprarlo!\nSolo representa el ${percentage.toStringAsFixed(1)}% de tu capital disponible. Tu saldo quedaría en ${AppColors.formatCurrency(remaining)}.';
        });
      } else if (percentage < 50) {
         // Moderate
         setState(() {
          _resultColor = Colors.orange;
          _resultIcon = Icons.warning_amber_rounded;
          _resultMessage = 'Puedes comprarlo, pero ten cuidado.\nRepresenta el ${percentage.toStringAsFixed(1)}% de tu capital. Asegúrate de no necesitar ese dinero pronto.';
        });
      } else {
        // High impact
         setState(() {
          _resultColor = Colors.orangeAccent;
          _resultIcon = Icons.warning_amber_rounded;
          _resultMessage = 'Puedes comprarlo, pero es arriesgado.\nConsumirá el ${percentage.toStringAsFixed(1)}% de todos tus ahorros. ¿Es realmente una emergencia?';
        });
      }
    } else {
      // Scenario 2: Cannot pay now, need to save
      final deficit = price - _totalBalance!;
      
      if (_monthlySavingsAvg! > 0) {
        final monthsNeeded = (price / _monthlySavingsAvg!).ceil(); // Saving from 0
        final monthsToWait = (deficit / _monthlySavingsAvg!).ceil(); // Saving from current balance
        
        setState(() {
          _resultColor = Colors.redAccent;
          _resultIcon = Icons.access_time;
          _resultMessage = 'No te alcanza todavía.\nNecesitas ahorrar por ${monthsToWait} meses más (basado en tu ahorro promedio de ${AppColors.formatCurrency(_monthlySavingsAvg!)}).';
        });
      } else {
         setState(() {
          _resultColor = Colors.red;
          _resultIcon = Icons.block;
          _resultMessage = 'No te alcanza y tu ahorro mensual es nulo o negativo.\nPrimero necesitas mejorar tus finanzas antes de pensar en este gasto.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador de Compras'),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro
              Text(
                '¿Puedo darme este gusto?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Analiza si una compra afectará tu salud financiera.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Inputs
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '¿Qué quieres comprar?',
                  hintText: 'Ej. iPhone 15, Zapatillas...',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '¿Cuánto cuesta?',
                  hintText: '0',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el precio';
                  final n = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (n == null || n <= 0) return 'Precio inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action Button
              ElevatedButton(
                onPressed: _simulate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: const Text(
                  'Simular Compra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              
              const SizedBox(height: 32),

              // Stats Row (Info)
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Capital Disponible',
                      value: _totalBalance,
                      icon: Icons.account_balance_wallet,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _InfoCard(
                      title: 'Ahorro Promedio',
                      value: _monthlySavingsAvg,
                      icon: Icons.savings,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Result
              if (_resultMessage != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _resultColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _resultColor ?? Colors.grey, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(_resultIcon, size: 48, color: _resultColor),
                      const SizedBox(height: 16),
                      Text(
                        _resultMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _resultColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final double? value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? AppColors.formatCurrency(value!) : '...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
