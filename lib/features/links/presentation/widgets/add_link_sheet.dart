import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/url_validator.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/data/category_repository.dart';
import '../../data/link_repository.dart';
import '../../data/metadata_service.dart';
import '../../domain/link_model.dart';
import '../../data/metadata_worker.dart';

class AddLinkSheet extends ConsumerStatefulWidget {
  final String? prefilledUrl;

  const AddLinkSheet({super.key, this.prefilledUrl});

  @override
  ConsumerState<AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends ConsumerState<AddLinkSheet> {
  final _urlController = TextEditingController();
  final _labelController = TextEditingController();
  String _selectedCategory = 'Other';
  bool _isFetchingMetadata = false;
  bool _isSaving = false;
  LinkMetadata? _fetchedMetadata;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledUrl != null && widget.prefilledUrl!.isNotEmpty) {
      _urlController.text = widget.prefilledUrl!;
      _fetchMetadata(widget.prefilledUrl!);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata(String url) async {
    if (!UrlValidator.isValidUrl(url)) return;

    setState(() => _isFetchingMetadata = true);
    try {
      final metadata =
          await ref.read(metadataServiceProvider).fetchMetadata(url);
      if (mounted) {
        setState(() {
          _fetchedMetadata = metadata;
          if (metadata.title.isNotEmpty && _labelController.text.isEmpty) {
            _labelController.text = metadata.title;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isFetchingMetadata = false);
    }
  }

  Future<void> _saveLink() async {
    final url = UrlValidator.sanitize(_urlController.text);
    if (!UrlValidator.isValidUrl(url)) {
      SnackbarUtils.showError(context, 'Please enter a valid URL');
      return;
    }

    final label = _labelController.text.trim().isEmpty
        ? (_fetchedMetadata?.title ?? UrlValidator.extractDomain(url) ?? url)
        : _labelController.text.trim();

    setState(() => _isSaving = true);
    try {
      final link = LinkModel(
        id: '',
        url: url,
        label: label,
        category: _selectedCategory,
        faviconUrl:
            _fetchedMetadata?.faviconUrl ?? UrlValidator.getFaviconUrl(url),
        pageTitle: _fetchedMetadata?.title ?? '',
        createdAt: DateTime.now(),
      );
      final repo = ref.read(linkRepositoryProvider);
      final id = await repo.addLink(link);
      
      // Fetch metadata in background isolate
      if (_fetchedMetadata == null || _fetchedMetadata!.isEmpty) {
        final savedLink = link.copyWith(id: id);
        fetchMetadataInBackground(savedLink).then((metadata) {
          if (!metadata.isEmpty) {
            repo.updateLink(id, {
              'page_title': metadata.title,
              'favicon_url': metadata.faviconUrl,
            });
          }
        });
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        HapticFeedback.mediumImpact();
        SnackbarUtils.showSuccess(context, 'Link saved!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to save link');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createNewCategory() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        await ref.read(categoryRepositoryProvider).addCategory(name, DateTime.now().millisecondsSinceEpoch % 7);
        if (mounted) {
          setState(() {
            _selectedCategory = name;
          });
        }
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, 'Failed to create category');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoryNamesProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withOpacity(0.85),
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

                // Title
                Text('Save a Link', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 20),

                // URL field
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://example.com',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    suffixIcon: _isFetchingMetadata
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onEditingComplete: () {
                    _fetchMetadata(_urlController.text);
                  },
                  onChanged: (value) {
                    // Auto-fetch when a full URL is pasted
                    if (UrlValidator.isValidUrl(value) &&
                        _fetchedMetadata == null) {
                      _fetchMetadata(value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Label field
                TextFormField(
                  controller: _labelController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Give this link a name...',
                    prefixIcon: Icon(Icons.label_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 20),

                // Category selector
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
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedCategory = cat);
                        },
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
                              width: isSelected ? 1.5 : 1,
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
                    }).toList()
                      ..add(
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _createNewCategory();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '+ New',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => const Text('Failed to load categories', style: TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveLink,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bookmark_add_rounded, size: 20),
                    label: Text(_isSaving ? 'Saving...' : 'Save Link'),
                  ),
                ),
              ].animate(interval: 40.ms).fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0, duration: 250.ms, curve: Curves.easeOutQuad),
            ),
          ),
        ),
      ),
    );
  }

}
