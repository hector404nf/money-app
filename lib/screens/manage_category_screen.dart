import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';

class ManageCategoryScreen extends StatefulWidget {
  final Category? categoryToEdit;

  const ManageCategoryScreen({super.key, this.categoryToEdit});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late CategoryKind _selectedKind;
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _budgetController = TextEditingController(
      text: widget.categoryToEdit?.monthlyBudget?.toStringAsFixed(0) ?? '',
    );
    _selectedKind = widget.categoryToEdit?.kind ?? CategoryKind.expense;
    _selectedIcon = widget.categoryToEdit?.iconName;
    
    // Default icon if adding new
    if (widget.categoryToEdit == null) {
      _selectedIcon = 'category';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      final budget = double.tryParse(_budgetController.text);
      try {
        if (widget.categoryToEdit != null) {
          provider.editCategory(
            id: widget.categoryToEdit!.id,
            name: _nameController.text,
            iconName: _selectedIcon,
            monthlyBudget: budget,
          );
        } else {
          provider.addCategory(
            name: _nameController.text,
            kind: _selectedKind,
            iconName: _selectedIcon,
            monthlyBudget: budget,
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: const Text('¿Estás seguro de que quieres eliminar esta categoría? Si tiene transacciones asociadas, no se podrá eliminar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _deleteCategory();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory() {
    if (widget.categoryToEdit == null) return;
    
    final provider = Provider.of<DataProvider>(context, listen: false);
    try {
      provider.deleteCategory(widget.categoryToEdit!.id);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryToEdit != null;
    final title = isEditing ? 'Editar Categoría' : 'Nueva Categoría';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // backgroundColor: AppColors.background, // Handled by theme
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: theme.textTheme.titleLarge?.color)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.iconTheme.color),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name Input
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.cardTheme.color,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Budget Input
            if (_selectedKind == CategoryKind.expense) ...[
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Presupuesto Mensual (Opcional)',
                  prefixText: '₲ ',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.cardTheme.color,
                  helperText: 'Deja vacío para no establecer límite',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),
            ],

            // Type Selection
            Text('Tipo de Categoría', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<CategoryKind>(
              segments: const [
                ButtonSegment(
                  value: CategoryKind.expense,
                  label: Text('Gasto'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: CategoryKind.income,
                  label: Text('Ingreso'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_selectedKind},
              onSelectionChanged: isEditing 
                  ? null // Disable if editing
                  : (Set<CategoryKind> newSelection) {
                      setState(() {
                        _selectedKind = newSelection.first;
                      });
                    },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                     return _selectedKind == CategoryKind.expense 
                         ? AppColors.expense.withOpacity(0.2)
                         : AppColors.income.withOpacity(0.2);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            if (isEditing)
               const Padding(
                 padding: EdgeInsets.only(top: 8.0),
                 child: Text('El tipo de categoría no se puede cambiar después de crearla.', style: TextStyle(color: Colors.grey, fontSize: 12)),
               ),
            
            const SizedBox(height: 24),

            // Icon Picker
            Text('Icono', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              height: 300, // Fixed height for grid
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: IconHelper.availableIcons.length,
                itemBuilder: (context, index) {
                  final iconName = IconHelper.availableIcons[index];
                  final isSelected = _selectedIcon == iconName;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconName;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.2) : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                      ),
                      child: Icon(
                        IconHelper.getIconByName(iconName),
                        color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isEditing ? 'Guardar Cambios' : 'Crear Categoría'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
