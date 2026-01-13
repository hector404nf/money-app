import 'package:flutter/material.dart';
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
  late CategoryKind _selectedKind;
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
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
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      try {
        if (widget.categoryToEdit != null) {
          provider.editCategory(
            id: widget.categoryToEdit!.id,
            name: _nameController.text,
            iconName: _selectedIcon,
          );
        } else {
          provider.addCategory(
            name: _nameController.text,
            kind: _selectedKind,
            iconName: _selectedIcon,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
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
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Type Selection (Only if adding, usually changing type is risky for consistency but we can allow it if we want, but typically apps lock type after creation. Let's lock it if editing to simplify)
            // Wait, user might want to fix a mistake. But CategoryKind is used for logic.
            // Let's allow it only if creating, or maybe allow it but it might look weird for existing transactions.
            // For now, I'll allow changing it, but maybe warn? Or just disable if editing.
            // Disabling if editing is safer.
            
            Text('Tipo de Categoría', style: Theme.of(context).textTheme.titleMedium),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
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
                        color: isSelected ? AppColors.primary : Colors.grey.shade700,
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
