import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/link_repository.dart';
import '../../domain/link_model.dart';

class EditLinkSheet extends ConsumerStatefulWidget {
  final LinkModel link;

  const EditLinkSheet({super.key, required this.link});

  @override
  ConsumerState<EditLinkSheet> createState() => _EditLinkSheetState();
}

class _EditLinkSheetState extends ConsumerState<EditLinkSheet> {
  late TextEditingController _labelController;
  late String _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.link.label);
    _selectedCategory = widget.link.category;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(linkRepositoryProvider).updateLink(widget.link.id, {
        'label': _labelController.text.trim(),
        'category': _selectedCategory,
      });
      if (mounted) {
        Navigator.of(context).pop();
        SnackbarUtils.showSuccess(context, 'Link updated!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to update link');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoryNamesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text('Edit Link', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),

            // URL (read-only)
            Text(
              widget.link.url,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Label
            TextFormField(
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Label',
                prefixIcon: Icon(Icons.label_outline, size: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),

            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  final catColor = AppColors.getCategoryColor(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? catColor.background
                                : catColor.lightBackground)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? catColor.border : catColor.lightBorder)
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? catColor.text : catColor.lightText)
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => const Text('Failed to load categories'),
            ),
            const SizedBox(height: 28),

            // Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
