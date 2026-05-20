import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a saved link
class LinkModel {
  final String id;
  final String url;
  final String label;
  final String category;
  final String faviconUrl;
  final String pageTitle;
  final DateTime createdAt;
  final bool isFavourite;

  const LinkModel({
    required this.id,
    required this.url,
    required this.label,
    required this.category,
    this.faviconUrl = '',
    this.pageTitle = '',
    required this.createdAt,
    this.isFavourite = false,
  });

  factory LinkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LinkModel(
      id: doc.id,
      url: data['url'] ?? '',
      label: data['label'] ?? '',
      category: data['category'] ?? 'Other',
      faviconUrl: data['favicon_url'] ?? '',
      pageTitle: data['page_title'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavourite: data['is_favourite'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'label': label,
      'category': category,
      'favicon_url': faviconUrl,
      'page_title': pageTitle,
      'created_at': Timestamp.fromDate(createdAt),
      'is_favourite': isFavourite,
    };
  }

  LinkModel copyWith({
    String? id,
    String? url,
    String? label,
    String? category,
    String? faviconUrl,
    String? pageTitle,
    DateTime? createdAt,
    bool? isFavourite,
  }) {
    return LinkModel(
      id: id ?? this.id,
      url: url ?? this.url,
      label: label ?? this.label,
      category: category ?? this.category,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      pageTitle: pageTitle ?? this.pageTitle,
      createdAt: createdAt ?? this.createdAt,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }
}
