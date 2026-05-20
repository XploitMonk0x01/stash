import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the app
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photo_url'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
