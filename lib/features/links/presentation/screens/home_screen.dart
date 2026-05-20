import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/widgets/manage_categories_sheet.dart';
import '../../domain/link_model.dart';
import '../providers/link_providers.dart';
import '../widgets/add_link_sheet.dart';
import '../widgets/edit_link_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/link_card.dart';
import '../widgets/link_skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  ({String title, String subtitle}) _formatError(Object error) {
    if (error is FirebaseException && error.plugin == 'cloud_firestore') {
      if (error.code == 'permission-denied') {
        return (
          title: 'Permission denied',
          subtitle:
              'Firestore blocked this read. Update your Firestore Security Rules to allow reading your own data under users/<uid>/links and users/<uid>/categories.',
        );
      }

      if (error.code == 'failed-precondition') {
        return (
          title: 'Index required',
          subtitle:
              'This Firestore query needs a composite index. If you still see this after updating the app, create the index from the Firebase Console link in the error details.',
        );
      }
    }

    final message = error.toString();
    if (message.toLowerCase().contains('permission-denied')) {
      return (
        title: 'Permission denied',
        subtitle:
            'Firestore blocked this read. Check Firestore Security Rules for users/<uid>/links and users/<uid>/categories.',
      );
    }

    return (title: 'Something went wrong', subtitle: message);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddLinkSheet({String? prefilledUrl}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddLinkSheet(prefilledUrl: prefilledUrl),
    );
  }

  void _openEditLinkSheet(LinkModel link) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditLinkSheet(link: link),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final linksAsync = ref.watch(searchFilteredLinksProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final favouritesOnly = ref.watch(favouritesOnlyProvider);
    final categoriesAsync = ref.watch(categoryNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search links...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                style: theme.textTheme.bodyLarge,
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
              )
            : const Text('Stash'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(filteredLinksProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Category filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Favourites chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 16,
                                color: AppColors.favouriteStar),
                            SizedBox(width: 4),
                            Text('Favourites'),
                          ],
                        ),
                        selected: favouritesOnly,
                        onSelected: (v) {
                          HapticFeedback.lightImpact();
                          ref.read(favouritesOnlyProvider.notifier).state = v;
                        },
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.accent,
                      ),
                    ),
                    // All chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedCategory == null && !favouritesOnly,
                        onSelected: (_) {
                          HapticFeedback.lightImpact();
                          ref.read(selectedCategoryProvider.notifier).state = null;
                          ref.read(favouritesOnlyProvider.notifier).state = false;
                        },
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.accent,
                      ),
                    ),
                    // Category chips
                    ...categoriesAsync.when(
                      data: (categories) => categories.map((cat) {
                        final isSelected = selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) {
                              HapticFeedback.lightImpact();
                              ref.read(selectedCategoryProvider.notifier).state =
                                  isSelected ? null : cat;
                              ref.read(favouritesOnlyProvider.notifier).state =
                                  false;
                            },
                            selectedColor:
                                AppColors.accent.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.accent,
                          ),
                        );
                      }),
                      loading: () => [const SizedBox.shrink()],
                      error: (e, st) => [const SizedBox.shrink()],
                    ),
                    // Manage Categories Chip
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 16),
                      child: ActionChip(
                        label: const Icon(Icons.settings_outlined, size: 18),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DraggableScrollableSheet(
                              initialChildSize: 0.6,
                              minChildSize: 0.4,
                              maxChildSize: 0.9,
                              builder: (context, scrollController) => const ManageCategoriesSheet(),
                            ),
                          );
                        },
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Link list
            linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: _showSearch
                          ? 'No results found'
                          : favouritesOnly
                              ? 'No favourites yet'
                              : selectedCategory != null
                                  ? 'No links in $selectedCategory'
                                  : 'No links yet',
                      subtitle: _showSearch
                          ? 'Try a different search term'
                          : 'Tap + to save your first link',
                      icon: _showSearch
                          ? Icons.search_off_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return LinkCard(
                        link: link,
                        onEdit: () => _openEditLinkSheet(link),
                      ).animate(key: ValueKey(link.id))
                       .fadeIn(duration: 300.ms)
                       .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
                    },
                  ),
                );
              },
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: LinkListSkeleton(),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: _formatError(e).title,
                  subtitle: _formatError(e).subtitle,
                  icon: Icons.error_outline_rounded,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          _openAddLinkSheet();
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
