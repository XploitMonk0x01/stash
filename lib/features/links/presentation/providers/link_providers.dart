import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/link_repository.dart';
import '../../domain/link_model.dart';

/// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected category for filtering
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Whether to show favourites only
final favouritesOnlyProvider = StateProvider<bool>((ref) => false);

/// Stream of links based on current filters
final filteredLinksProvider = StreamProvider<List<LinkModel>>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final favouritesOnly = ref.watch(favouritesOnlyProvider);

  return repository.watchLinks().map((links) {
    Iterable<LinkModel> filtered = links.where((l) => !l.isArchived);
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((l) => l.category == category);
    }
    if (favouritesOnly) {
      filtered = filtered.where((l) => l.isFavourite);
    }
    return filtered.toList();
  });
});

/// Search-filtered links (client-side filter on top of Firestore stream)
final searchFilteredLinksProvider = Provider<AsyncValue<List<LinkModel>>>((ref) {
  final linksAsync = ref.watch(filteredLinksProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return linksAsync.whenData((links) {
    if (query.isEmpty) return links;
    return links.where((link) {
      return link.label.toLowerCase().contains(query) ||
          link.url.toLowerCase().contains(query) ||
          link.pageTitle.toLowerCase().contains(query);
    }).toList();
  });
});

/// Total link count for the current user
final linkCountProvider = FutureProvider<int>((ref) {
  return ref.watch(linkRepositoryProvider).getLinkCount();
});
