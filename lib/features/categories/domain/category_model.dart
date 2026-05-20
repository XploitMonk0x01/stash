import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a link category
class CategoryModel {
  final String id;
  final String name;
  final int colorIndex;
  final bool isDefault;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.colorIndex = 6,
    this.isDefault = false,
    required this.createdAt,
  });

  /// Default categories seeded on first signup
  static List<CategoryModel> get defaults => [
        CategoryModel(
          id: 'dev_tools',
          name: 'Dev Tools',
          colorIndex: 0,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'design',
          name: 'Design',
          colorIndex: 1,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'learning',
          name: 'Learning',
          colorIndex: 2,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'finance',
          name: 'Finance',
          colorIndex: 3,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'news',
          name: 'News',
          colorIndex: 4,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'entertainment',
          name: 'Entertainment',
          colorIndex: 5,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: 'other',
          name: 'Other',
          colorIndex: 6,
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      ];

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      colorIndex: data['color_index'] ?? 6,
      isDefault: data['is_default'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color_index': colorIndex,
      'is_default': isDefault,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? colorIndex,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
