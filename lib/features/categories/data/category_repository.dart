import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_model.dart';

/// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Repository for category CRUD operations
class CategoryRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CategoryRepository({required this.firestore, required this.auth});

  String get _uid {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  CollectionReference get _categoriesRef =>
      firestore.collection('users/$_uid/categories');

  /// Watch all categories as a stream
  Stream<List<CategoryModel>> watchCategories() {
    return _categoriesRef
        .orderBy('created_at')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _categoriesRef.orderBy('created_at').get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc))
        .toList();
  }

  /// Add a new custom category
  Future<String> addCategory(String name, int colorIndex) async {
    final doc = _categoriesRef.doc();
    await doc.set({
      'name': name.trim(),
      'color_index': colorIndex,
      'is_default': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Rename a category
  Future<void> renameCategory(String categoryId, String newName) async {
    await _categoriesRef.doc(categoryId).update({'name': newName.trim()});
  }

  /// Delete a category (moves links with this category to "Other")
  Future<void> deleteCategory(String categoryId, String categoryName) async {
    // Update all links with this category to "Other"
    final linksRef = firestore.collection('users/$_uid/links');
    final linksToUpdate = await linksRef
        .where('category', isEqualTo: categoryName)
        .get();

    final batch = firestore.batch();
    for (final doc in linksToUpdate.docs) {
      batch.update(doc.reference, {'category': 'Other'});
    }

    // Delete the category
    batch.delete(_categoriesRef.doc(categoryId));
    await batch.commit();
  }
}
