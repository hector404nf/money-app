
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/data_provider.dart';
import '../models/category_rule.dart';
import '../models/category.dart';
import '../utils/constants.dart';

class CategoryRulesScreen extends StatelessWidget {
  const CategoryRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglas de Categorización'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: theme.iconTheme.color),
      ),
      body: provider.categoryRules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rule, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reglas definidas',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea reglas para asignar categorías\nautomáticamente según el texto.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.categoryRules.length,
              itemBuilder: (context, index) {
                final rule = provider.categoryRules[index];
                final category = provider.categories.firstWhere(
                  (c) => c.id == rule.categoryId,
                  orElse: () => Category(id: '', name: 'Desconocida', kind: CategoryKind.expense),
                );

                return Dismissible(
                  key: Key(rule.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    provider.deleteCategoryRule(rule.id);
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    child: ListTile(
                      title: Text(
                        rule.rulePattern,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        'Asigna a: ${category.name}',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (rule.isStrict)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.5)),
                              ),
                              child: const Text(
                                'Exacto',
                                style: TextStyle(fontSize: 10, color: Colors.blue),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Switch(
                            value: rule.active,
                            onChanged: (val) {
                              provider.updateCategoryRule(rule.copyWith(active: val));
                            },
                          ),
                        ],
                      ),
                      onTap: () => _showRuleDialog(context, rule: rule),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRuleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRuleDialog(BuildContext context, {CategoryRule? rule}) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final isEditing = rule != null;
    
    final patternController = TextEditingController(text: rule?.rulePattern ?? '');
    String selectedCategoryId = rule?.categoryId ?? (provider.categories.isNotEmpty ? provider.categories.first.id : '');
    bool isStrict = rule?.isStrict ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return AlertDialog(
            title: Text(isEditing ? 'Editar Regla' : 'Nueva Regla'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: patternController,
                    decoration: const InputDecoration(
                      labelText: 'Palabra clave o frase',
                      hintText: 'Ej: Uber, Netflix, Super',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría a asignar',
                      border: OutlineInputBorder(),
                    ),
                    items: provider.categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.name,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedCategoryId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Coincidencia Exacta'),
                    subtitle: const Text('Solo si la palabra está aislada'),
                    value: isStrict,
                    onChanged: (val) {
                      setState(() => isStrict = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (patternController.text.trim().isEmpty) return;
                  
                  final newRule = CategoryRule(
                    id: isEditing ? rule.id : const Uuid().v4(),
                    rulePattern: patternController.text.trim(),
                    categoryId: selectedCategoryId,
                    active: true,
                    isStrict: isStrict,
                  );
                  
                  if (isEditing) {
                    provider.updateCategoryRule(newRule);
                  } else {
                    provider.addCategoryRule(newRule);
                  }
                  
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
