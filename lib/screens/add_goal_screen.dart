import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';

import '../models/goal.dart';

class AddGoalScreen extends StatefulWidget {
  final Goal? goal;
  const AddGoalScreen({super.key, this.goal});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  DateTime? _deadline;
  Color _selectedColor = Colors.blue;
  String _selectedIcon = 'savings';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _amountController = TextEditingController(
      text: widget.goal != null ? widget.goal!.targetAmount.toStringAsFixed(0) : '',
    );
    _deadline = widget.goal?.deadline;
    if (widget.goal != null) {
      _selectedColor = Color(widget.goal!.colorValue);
      _selectedIcon = widget.goal!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  final List<String> _icons = [
    'savings',
    'directions_car',
    'home',
    'flight',
    'star',
    'school',
    'medical_services',
    'laptop',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: Colors.white, // Handled by theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.goal != null ? 'Editar Meta' : 'Nueva Meta',
          style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Icon and Color Preview
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _selectedColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconHelper.getIconByName(_selectedIcon),
                    color: _selectedColor,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la meta',
                  hintText: 'Ej. Auto Nuevo',
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto objetivo',
                  hintText: '0',
                  prefixText: 'Gs. ',
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
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
              const SizedBox(height: 16),

              // Deadline Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark 
                              ? const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.darkTextPrimary,
                                  surface: AppColors.darkSurface,
                                )
                              : const ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() => _deadline = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline == null
                              ? 'Fecha objetivo (Opcional)'
                              : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                          style: TextStyle(
                            color: _deadline == null ? (isDark ? Colors.grey[400] : Colors.grey[600]) : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Color Selection
              Text('Color', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = _colors[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: _selectedColor == color
                              ? Border.all(color: isDark ? Colors.white : AppColors.textPrimary, width: 2)
                              : null,
                        ),
                        child: _selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Icon Selection
              Text('Ícono', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _icons.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? _selectedColor.withOpacity(0.1) : theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: _selectedColor, width: 2) : null,
                      ),
                      child: Icon(
                        IconHelper.getIconByName(iconName),
                        color: isSelected ? _selectedColor : (isDark ? Colors.grey.shade400 : AppColors.textSecondary),
                        size: 28,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.goal != null ? 'Guardar Cambios' : 'Crear Meta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      final navigator = Navigator.of(context);
      // final messenger = ScaffoldMessenger.of(context);
      
      if (widget.goal != null) {
        provider.editGoal(
          id: widget.goal!.id,
          name: _nameController.text,
          targetAmount: double.parse(_amountController.text),
          deadline: _deadline,
          colorValue: _selectedColor.value,
          iconName: _selectedIcon,
        );
        if (mounted) {
          //  messenger.showSnackBar(
          //    const SnackBar(content: Text('Meta actualizada exitosamente')),
          //  );
           navigator.pop();
        }
      } else {
        provider.addGoal(
          name: _nameController.text,
          targetAmount: double.parse(_amountController.text),
          deadline: _deadline,
          colorValue: _selectedColor.value,
          iconName: _selectedIcon,
        );
        if (mounted) {
          //  messenger.showSnackBar(
          //    const SnackBar(content: Text('Meta creada exitosamente')),
          //  );
           navigator.pop();
        }
      }
    }
  }

}
