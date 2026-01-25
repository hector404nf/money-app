import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/category.dart';
import '../utils/constants.dart';
import '../utils/icon_helper.dart';
import 'manage_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Categorías', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(color: theme.iconTheme.color),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Gastos'),
              Tab(text: 'Ingresos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(kind: CategoryKind.expense),
            _CategoryList(kind: CategoryKind.income),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageCategoryScreen()),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final CategoryKind kind;

  const _CategoryList({required this.kind});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<DataProvider>(
      builder: (context, provider, _) {
        final categories = provider.categories
            .where((c) => c.kind == kind)
            .toList();

        if (categories.isEmpty) {
          return const Center(
            child: Text(
              'No hay categorías',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            
            // Determine icon
            IconData iconData;
            if (category.iconName != null) {
              iconData = IconHelper.getIconByName(category.iconName!);
            } else {
              iconData = IconHelper.getCategoryIcon(category.name);
            }

            return Card(
              elevation: 0,
              color: theme.cardTheme.color,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kind == CategoryKind.expense 
                      ? AppColors.expense.withOpacity(0.1) 
                      : AppColors.income.withOpacity(0.1),
                  child: Icon(
                    iconData,
                    color: kind == CategoryKind.expense ? AppColors.expense : AppColors.income,
                    size: 20,
                  ),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageCategoryScreen(categoryToEdit: category),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
