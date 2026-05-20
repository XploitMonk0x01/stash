import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/category_repository.dart';
import '../../domain/category_model.dart';

/// Stream of all categories
final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

/// Category names list (for quick access in dropdowns/chips)
final categoryNamesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(categoriesStreamProvider).whenData(
        (categories) => categories.map((c) => c.name).toList(),
      );
});
