import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';

class AddAccountModal extends StatefulWidget {
  final Account? account;

  const AddAccountModal({super.key, this.account});

  static void show(BuildContext context, {Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAccountModal(account: account),
    );
  }

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account?.initialBalance.toString() ?? '0',
    );
    _selectedType = widget.account?.type ?? AccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final balance = double.tryParse(_balanceController.text) ?? 0.0;
      final provider = Provider.of<DataProvider>(context, listen: false);

      if (widget.account != null) {
        // Editar
        provider.editAccount(
          id: widget.account!.id,
          name: name,
          initialBalance: balance,
          type: _selectedType,
        );
      } else {
        // Crear
        provider.addAccount(
          name: name,
          initialBalance: balance,
          type: _selectedType,
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  isEditing ? 'Editar Cuenta' : 'Nueva Cuenta',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la cuenta',
                    hintText: 'Ej. Billetera, Banco X',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.cardTheme.color,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // Initial Balance Field
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Saldo actual',
                    prefixText: 'Gs. ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: theme.cardTheme.color,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un monto';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Account Type Selection
                Text(
                  'Tipo de cuenta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AccountType.values.length,
                    separatorBuilder: (context, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final type = AccountType.values[index];
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: isSelected ? type.color : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? type.color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: type.color.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type.icon,
                                color: isSelected ? Colors.white : type.color,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Guardar Cambios' : 'Crear Cuenta',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
