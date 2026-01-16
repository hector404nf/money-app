import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';

enum TransactionFlow {
  expense,
  income,
  transfer,
}

class AddTransactionScreen extends StatefulWidget {
  final TransactionFlow? initialFlow;
  final String? initialAccountId;
  final String? initialToAccountId;

  const AddTransactionScreen({
    super.key,
    this.initialFlow,
    this.initialAccountId,
    this.initialToAccountId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  TransactionFlow _flow = TransactionFlow.expense;
  double? _amount;
  String? _categoryId;
  String? _accountId;
  String? _fromAccountId;
  String? _toAccountId;
  DateTime _selectedDate = DateTime.now();
  final _notesController = TextEditingController();

  TransactionStatus _status = TransactionStatus.pagado;
  DateTime? _dueDate;
  RecurringFrequency? _recurringFrequency;

  @override
  void initState() {
    super.initState();
    if (widget.initialFlow != null) {
      _flow = widget.initialFlow!;
    }
    
    if (widget.initialAccountId != null) {
       if (_flow == TransactionFlow.transfer) {
          _fromAccountId = widget.initialAccountId;
       } else {
          _accountId = widget.initialAccountId;
       }
    }
    
    if (widget.initialToAccountId != null && _flow == TransactionFlow.transfer) {
       _toAccountId = widget.initialToAccountId;
    }
  }

  // Helper getters
  bool get isExpense => _flow == TransactionFlow.expense;
  bool get isIncome => _flow == TransactionFlow.income;
  bool get isTransfer => _flow == TransactionFlow.transfer;
  
  Color get flowColor => isExpense
      ? AppColors.expense
      : isIncome
          ? AppColors.income
          : AppColors.transfer;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildTypeButton(TransactionFlow flow, String label) {
    final isSelected = _flow == flow;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final color = flow == TransactionFlow.expense 
        ? AppColors.expense 
        : flow == TransactionFlow.income 
            ? AppColors.income 
            : AppColors.transfer;
        
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _flow = flow;
            _categoryId = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoriesToShow = provider.categories.where((c) {
      if (isExpense) return c.kind == CategoryKind.expense;
      if (isIncome) return c.kind == CategoryKind.income;
      return false;
    }).toList();

    return Scaffold(
      // backgroundColor: AppColors.background, // Handled by theme
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Let scaffold background show through
        foregroundColor: theme.textTheme.titleLarge?.color,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nueva transacción', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTypeButton(TransactionFlow.expense, 'Gasto'),
                      _buildTypeButton(TransactionFlow.income, 'Ingreso'),
                      _buildTypeButton(TransactionFlow.transfer, 'Transf.'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              Center(
                child: IntrinsicWidth(
                  child: TextFormField(
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: flowColor,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₲ ',
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa monto';
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) return 'Inválido';
                      return null;
                    },
                    onSaved: (value) => _amount = double.parse(value!),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? theme.scaffoldBackgroundColor : AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionLabel('Fecha', Icons.calendar_today),
                        const SizedBox(height: 12),
                        _buildDateSelector(),
                        const SizedBox(height: 24),

                        if (!isTransfer) ...[
                          _buildStatusSelector(),
                          const SizedBox(height: 24),
                          _buildDueDateSelector(),
                          const SizedBox(height: 24),
                          _buildRecurringSection(),
                          const SizedBox(height: 24),
                          _buildSectionLabel('Cuenta', Icons.account_balance_wallet),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            key: ValueKey('account_${_flow}_$_accountId'),
                            value: _accountId,
                            items: provider.accounts.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                            onChanged: (v) => setState(() => _accountId = v),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel('Categoría', Icons.category),
                          const SizedBox(height: 12),
                          _buildCategoryGrid(categoriesToShow),
                        ] else ...[
                          _buildSectionLabel('Desde', Icons.call_made),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            key: ValueKey('fromAccount_$_fromAccountId'),
                            value: _fromAccountId,
                            items: _getAccountItems(provider),
                            onChanged: (v) => setState(() => _fromAccountId = v),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionLabel('Hacia', Icons.call_received),
                          const SizedBox(height: 12),
                          _buildDropdown(
                            key: ValueKey('toAccount_$_toAccountId'),
                            value: _toAccountId,
                            items: _getAccountItems(provider),
                            onChanged: (v) => setState(() => _toAccountId = v),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        _buildSectionLabel('Nota (opcional)', Icons.note),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Agregar una nota...',
                            filled: true,
                            fillColor: isDark ? Colors.black26 : Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _saveTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: flowColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              shadowColor: flowColor.withValues(alpha: 0.4),
                            ),
                            child: Text(
                              isTransfer 
                                  ? 'Guardar Transferencia' 
                                  : isExpense 
                                      ? 'Guardar Gasto' 
                                      : 'Guardar Ingreso',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.iconTheme.color?.withOpacity(0.7) ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    bool isToday = selected == today;
    bool isYesterday = selected == yesterday;
    bool isOther = !isToday && !isYesterday;

    return Row(
      children: [
        _DateChip(
          label: 'Hoy',
          isSelected: isToday,
          color: flowColor,
          onTap: () => setState(() => _selectedDate = DateTime.now()),
        ),
        const SizedBox(width: 12),
        _DateChip(
          label: 'Ayer',
          isSelected: isYesterday,
          color: flowColor,
          onTap: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1))),
        ),
        const SizedBox(width: 12),
        _DateChip(
          label: isOther ? '${_selectedDate.day}/${_selectedDate.month}' : 'Otro',
          isSelected: isOther,
          color: flowColor,
          icon: Icons.calendar_today,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getAccountItems(DataProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final accountItems = provider.accounts.map((e) => DropdownMenuItem(
          value: e.id,
          child: Text(e.name, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        ));

    final goalItems = provider.goals.map((e) => DropdownMenuItem(
          value: e.id,
          child: Row(
            children: [
              const Icon(Icons.flag, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(e.name, style: const TextStyle(color: AppColors.secondary)),
            ],
          ),
        ));

    return [...accountItems, ...goalItems];
  }

  Widget _buildDropdown({
    Key? key,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: key,
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: theme.cardTheme.color,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color?.withOpacity(0.5)),
          hint: Text('Seleccionar...', style: TextStyle(color: theme.hintColor)),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 36) / 4; // 4 columns, 12px spacing * 3 gaps
        
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...categories.map((cat) {
              final isSelected = _categoryId == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _categoryId = cat.id),
                child: SizedBox(
                  width: itemWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected 
                                ? Border.all(color: flowColor, width: 2) 
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? flowColor.withValues(alpha: 0.2) : Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              cat.iconName != null ? IconHelper.getIconByName(cat.iconName!) : IconHelper.getCategoryIcon(cat.name),
                              color: isSelected ? flowColor : theme.iconTheme.color,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? flowColor : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Add Button
            GestureDetector(
              onTap: () async {
                final createdId = await _createCategory(
                  kind: isExpense ? CategoryKind.expense : CategoryKind.income,
                );
                if (createdId != null && mounted) {
                  setState(() => _categoryId = createdId);
                }
              },
              child: SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            style: BorderStyle.solid, 
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                              const SizedBox(height: 4),
                              Text(
                                'Crear',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Spacing for label alignment
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Validation for Dropdowns
      if (!isTransfer && _accountId == null) {
        _showError('Selecciona una cuenta');
        return;
      }
      if (!isTransfer && _categoryId == null) {
        _showError('Selecciona una categoría');
        return;
      }
      if (isTransfer && (_fromAccountId == null || _toAccountId == null)) {
        _showError('Selecciona cuentas de origen y destino');
        return;
      }
      if (isTransfer && _fromAccountId == _toAccountId) {
        _showError('Las cuentas deben ser diferentes');
        return;
      }

      try {
        final provider = Provider.of<DataProvider>(context, listen: false);
        final notes = _notesController.text.isNotEmpty ? _notesController.text : null;

        if (isTransfer) {
          provider.addTransfer(
            amount: _amount!,
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            date: _selectedDate,
            notes: notes,
          );
          _showSuccess('Transferencia guardada');
        } else {
          final finalAmount = isExpense ? -(_amount!.abs()) : _amount!.abs();
          provider.addTransaction(
            amount: finalAmount,
            categoryId: _categoryId!,
            accountId: _accountId!,
            date: _selectedDate,
            notes: notes,
            mainType: isExpense ? MainType.expenses : MainType.incomes,
            status: _status,
            dueDate: _dueDate,
            isRecurring: _recurringFrequency != null,
            frequency: _recurringFrequency,
          );
          _showSuccess('Movimiento guardado');
        }

        Navigator.pop(context);
      } catch (e) {
        _showError(e.toString());
      }
    }
  }
  
  Widget _buildStatusSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Estado', Icons.info_outline),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildStatusOption(TransactionStatus.pagado, 'Pagado'),
              _buildStatusOption(TransactionStatus.pendiente, 'Pendiente'),
              _buildStatusOption(TransactionStatus.programado, 'Programado'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildChip(RecurringFrequency? value, String label) {
      final bool isSelected = (_recurringFrequency == null && value == null) ||
          (_recurringFrequency != null && _recurringFrequency == value);

      final Color selectedColor = flowColor;
      final Color borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

      return GestureDetector(
        onTap: () {
          setState(() {
            _recurringFrequency = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? selectedColor : borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Repetir', Icons.repeat),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            buildChip(null, 'No repetir'),
            buildChip(RecurringFrequency.weekly, 'Semanal'),
            buildChip(RecurringFrequency.monthly, 'Mensual'),
            buildChip(RecurringFrequency.yearly, 'Anual'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption(TransactionStatus status, String label) {
    final isSelected = _status == status;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? flowColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    if (_status == TransactionStatus.pagado) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Fecha de Vencimiento', Icons.event_busy),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
               builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark 
                        ? ColorScheme.dark(
                            primary: flowColor,
                            onPrimary: Colors.white,
                            onSurface: AppColors.darkTextPrimary,
                            surface: AppColors.darkSurface,
                          )
                        : ColorScheme.light(
                            primary: flowColor,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textPrimary,
                          ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: flowColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  _dueDate == null 
                      ? 'Seleccionar fecha...' 
                      : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  style: TextStyle(
                    color: _dueDate == null 
                        ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary) 
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_dueDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _dueDate = null),
                    child: Icon(Icons.close, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Future<String?> _createCategory({required CategoryKind kind}) async {
    final messengerContext = context;
    var name = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => name = v,
            onSubmitted: (_) => _tryCreateCategory(
              dialogContext: dialogContext,
              messengerContext: messengerContext,
              kind: kind,
              name: name,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () => _tryCreateCategory(
                dialogContext: dialogContext,
                messengerContext: messengerContext,
                kind: kind,
                name: name,
              ),
              child: const Text('CREAR'),
            ),
          ],
        );
      },
    );
  }

  void _tryCreateCategory({
    required BuildContext dialogContext,
    required BuildContext messengerContext,
    required CategoryKind kind,
    required String name,
  }) {
    try {
      final provider = Provider.of<DataProvider>(dialogContext, listen: false);
      final id = provider.addCategory(
        name: name,
        kind: kind,
      );
      Navigator.pop(dialogContext, id);
    } catch (e) {
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey[600])),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey[600]),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
