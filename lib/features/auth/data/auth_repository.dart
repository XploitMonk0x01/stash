import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/app_user.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

/// Provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Reactive provider for current AppUser from Firestore
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream<AppUser?>.empty();
  return ref.watch(authRepositoryProvider).watchUser(user.uid);
});

/// Repository handling all Firebase Auth operations
class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  AuthRepository({
    required this.auth,
    required this.firestore,
    required this.googleSignIn,
  });

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Get the currently signed-in user
  User? get currentUser => auth.currentUser;

  /// Get user document from Firestore
  Future<AppUser?> getUser(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Watch user document as a stream
  Stream<AppUser?> watchUser(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<void> _ensureUserDocAndCategories(User user) async {
    final userDocRef = firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      final appUser = AppUser(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await userDocRef.set(appUser.toFirestore());
    }

  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Sign up failed');

    // Update display name
    await user.updateDisplayName(name.trim());

    // Create Firestore user document
    final appUser = AppUser(
      uid: user.uid,
      name: name.trim(),
      email: email.trim(),
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await firestore.collection('users').doc(user.uid).set(appUser.toFirestore());

  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Sign in failed');
    await _ensureUserDocAndCategories(user);
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Google Sign-In failed');

    await _ensureUserDocAndCategories(user);
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }

  /// Delete account and all user data
  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final uid = user.uid;

    // Delete all links subcollection
    final links = await firestore.collection('users/$uid/links').get();
    for (final doc in links.docs) {
      await doc.reference.delete();
    }

    // Delete all categories subcollection
    final categories =
        await firestore.collection('users/$uid/categories').get();
    for (final doc in categories.docs) {
      await doc.reference.delete();
    }

    // Delete user document
    await firestore.collection('users').doc(uid).delete();

    // Delete Firebase Auth account
    await user.delete();
  }

}
