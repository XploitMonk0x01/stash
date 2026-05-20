import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../providers/category_providers.dart';
import '../../data/category_repository.dart';
import '../../domain/category_model.dart';

class ManageCategoriesSheet extends ConsumerWidget {
  const ManageCategoriesSheet({super.key});

  Future<void> _renameCategory(BuildContext context, WidgetRef ref, CategoryModel category) async {
    final nameController = TextEditingController(text: category.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != category.name) {
      try {
        await ref.read(categoryRepositoryProvider).renameCategory(category.id, newName);
      } catch (e) {
        if (context.mounted) SnackbarUtils.showError(context, 'Failed to rename category');
      }
    }
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"? Links in this category will be moved to "Other".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(categoryRepositoryProvider).deleteCategory(category.id, category.name);
      } catch (e) {
        if (context.mounted) SnackbarUtils.showError(context, 'Failed to delete category');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage Categories', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return Center(
                    child: Text(
                      'No custom categories yet.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catColor = AppColors.getCategoryColor(cat.name);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark ? catColor.background : catColor.lightBackground,
                        radius: 16,
                        child: Icon(Icons.label_rounded, size: 16, color: isDark ? catColor.text : catColor.lightText),
                      ),
                      title: Text(cat.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _renameCategory(context, ref, cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                            onPressed: () => _deleteCategory(context, ref, cat),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('Failed to load categories')),
            ),
          ),
        ],
      ),
    );
  }
}
