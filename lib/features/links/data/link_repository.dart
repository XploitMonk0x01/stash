import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/link_model.dart';

/// Provider for LinkRepository
final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

/// Repository for all link CRUD operations, scoped to the current user
class LinkRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  LinkRepository({required this.firestore, required this.auth});

  Future<T> _guard<T>(Future<T> Function() action, String label) async {
    try {
      return await action();
    } catch (e) {
      throw Exception('$label failed: $e');
    }
  }

  String get _uid {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  CollectionReference get _linksRef =>
      firestore.collection('users/$_uid/links');

  Query get _linksQuery => _linksRef.orderBy('created_at', descending: true);

  /// Add a new link
  Future<String> addLink(LinkModel link) async {
    return _guard(() async {
      final doc = _linksRef.doc();
      final linkWithId = link.copyWith(id: doc.id);
      await doc.set(linkWithId.toFirestore());
      return doc.id;
    }, 'Add link');
  }

  /// Update an existing link
  Future<void> updateLink(String linkId, Map<String, dynamic> updates) async {
    await _guard(
      () => _linksRef.doc(linkId).update(updates),
      'Update link',
    );
  }

  /// Delete a link
  Future<void> deleteLink(String linkId) async {
    await _guard(
      () => _linksRef.doc(linkId).delete(),
      'Delete link',
    );
  }

  /// Soft-delete (archive) a link
  Future<void> archiveLink(String linkId) async {
    await _guard(
      () => _linksRef.doc(linkId).update({'is_archived': true}),
      'Archive link',
    );
  }

  /// Restore an archived link
  Future<void> unarchiveLink(String linkId) async {
    await _guard(
      () => _linksRef.doc(linkId).update({'is_archived': false}),
      'Unarchive link',
    );
  }

  /// Restore a previously deleted link using its original id.
  Future<void> restoreLink(LinkModel link) async {
    await _guard(
      () => _linksRef.doc(link.id).set(link.toFirestore()),
      'Restore link',
    );
  }

  /// Toggle favourite status
  Future<void> toggleFavourite(String linkId, bool isFavourite) async {
    await _guard(
      () => _linksRef.doc(linkId).update({'is_favourite': isFavourite}),
      'Toggle favourite',
    );
  }

  /// Get a stream of all links, optionally filtered
  Stream<List<LinkModel>> watchLinks({
    String? category,
    bool favouritesOnly = false,
  }) {
    // NOTE: Even though this method accepts filters, we intentionally do NOT
    // apply them at the Firestore query level.
    //
    // Reason: `where(is_favourite==true) + orderBy(created_at)` often requires
    // a composite index. Filtering client-side keeps the app functional without
    // requiring Firestore index setup.
    return _linksQuery.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList();
    });
  }

  /// Get paginated links
  Future<List<LinkModel>> getLinks({
    String? category,
    bool favouritesOnly = false,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _linksQuery;

    query = query.where('is_archived', isEqualTo: false);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (favouritesOnly) {
      query = query.where('is_favourite', isEqualTo: true);
    }

    query = query.limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => LinkModel.fromFirestore(doc)).toList();
  }

  /// Get a single link by ID
  Future<LinkModel?> getLink(String linkId) async {
    final doc = await _linksRef.doc(linkId).get();
    if (!doc.exists) return null;
    return LinkModel.fromFirestore(doc);
  }

  /// Get total link count for the current user
  Future<int> getLinkCount() async {
    final snapshot = await _linksRef
        .where('is_archived', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get link count for a specific category
  Future<int> getCategoryLinkCount(String category) async {
    final snapshot = await _linksRef
        .where('category', isEqualTo: category)
        .where('is_archived', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
