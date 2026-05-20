import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../links/data/link_repository.dart';
import '../../../links/presentation/widgets/empty_state.dart';
import '../../data/category_repository.dart';
import '../../domain/category_model.dart';
import '../providers/category_providers.dart';
import '../../../links/presentation/providers/link_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  ({String title, String subtitle}) _formatError(Object error) {
    if (error is FirebaseException && error.plugin == 'cloud_firestore') {
      if (error.code == 'permission-denied') {
        return (
          title: 'Permission denied',
          subtitle:
              'Firestore blocked this read. Update your Firestore Security Rules to allow reading your own categories under users/<uid>/categories.',
        );
      }
    }

    final message = error.toString();
    if (message.toLowerCase().contains('permission-denied')) {
      return (
        title: 'Permission denied',
        subtitle:
            'Firestore blocked this read. Check Firestore Security Rules for users/<uid>/categories.',
      );
    }

    return (title: 'Something went wrong', subtitle: message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: categories.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return _buildAddCategoryCard(context, ref, isDark, categories.length);
              }
              final cat = categories[index];
              return _buildCategoryCard(context, ref, cat, isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: _formatError(e).title,
          subtitle: _formatError(e).subtitle,
          icon: Icons.lock_outline_rounded,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
    bool isDark,
  ) {
    final catColor = AppColors.getCategoryColor(cat.name);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = cat.name;
        context.go('/home');
      },
      onLongPress: () => _showCategoryOptions(context, ref, cat),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? catColor.background : catColor.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? catColor.border : catColor.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isDark ? catColor.text : catColor.lightText)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(cat.name),
                size: 20,
                color: isDark ? catColor.text : catColor.lightText,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isDark ? catColor.text : catColor.lightText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FutureBuilder<int>(
                  future: ref
                      .read(linkRepositoryProvider)
                      .getCategoryLinkCount(cat.name),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return Text(
                      '$count link${count == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: (isDark ? catColor.text : catColor.lightText)
                            .withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    int existingCount,
  ) {
    return GestureDetector(
      onTap: () => _showAddCategoryDialog(context, ref, existingCount),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 32,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Category',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameCategoryDialog(context, ref, cat);
              },
            ),
            if (!cat.isDefault)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCategory(context, ref, cat);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    int existingCount,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await ref
                  .read(categoryRepositoryProvider)
                  .addCategory(name, existingCount % 7);
              if (context.mounted) {
                Navigator.pop(context);
                SnackbarUtils.showSuccess(context, 'Category created');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) {
    final controller = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await ref
                  .read(categoryRepositoryProvider)
                  .renameCategory(cat.id, name);
              if (context.mounted) {
                Navigator.pop(context);
                SnackbarUtils.showSuccess(context, 'Category renamed');
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'All links in "${cat.name}" will be moved to "Other". This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref
                  .read(categoryRepositoryProvider)
                  .deleteCategory(cat.id, cat.name);
              if (context.mounted) {
                Navigator.pop(context);
                SnackbarUtils.showSuccess(context, 'Category deleted');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Dev Tools':
        return Icons.code_rounded;
      case 'Design':
        return Icons.palette_rounded;
      case 'Learning':
        return Icons.school_rounded;
      case 'Finance':
        return Icons.account_balance_rounded;
      case 'News':
        return Icons.newspaper_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Other':
        return Icons.folder_rounded;
      default:
        return Icons.label_rounded;
    }
  }
}
