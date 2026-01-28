import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../main.dart' show isFirebaseInitialized;

class FirebaseAuthService {
  firebase_auth.FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  
  FirebaseAuthService() {
    if (isFirebaseInitialized) {
      try {
        _auth = firebase_auth.FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firebase services not available: $e');
        _auth = null;
        _firestore = null;
      }
    }
  }

  bool get isAvailable => _auth != null && _firestore != null;

  // Current user stream
  Stream<firebase_auth.User?> get authStateChanges {
    if (!isAvailable) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  // Current user
  firebase_auth.User? get currentUser => _auth?.currentUser;

  // Register
  Future<User?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      debugPrint('Firebase not available - registration disabled');
      return null;
    }
    
    try {
      // Create auth user
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Update display name
      await credential.user!.updateDisplayName(username);

      // Create user document in Firestore
      final user = User(
        id: credential.user!.uid.hashCode,
        username: username,
        email: email,
        role: 'user',
        createdAt: DateTime.now(),
        avatarUrl: null,
        uid: credential.user!.uid,
      );

      await _firestore!.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'avatarUrl': null,
      });

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Registration error: ${e.message}');
      throw _mapFirebaseError(e);
    }
  }

  // Login
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      debugPrint('Firebase not available - login disabled');
      return null;
    }
    
    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Get user data from Firestore
      final doc = await _firestore!
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return User(
        id: credential.user!.uid.hashCode,
        username: data['username'] ?? credential.user!.displayName ?? 'User',
        email: credential.user!.email!,
        role: data['role'] ?? 'user',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        avatarUrl: data['avatarUrl'],
        uid: credential.user!.uid,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Login error: ${e.message}');
      throw _mapFirebaseError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    if (isAvailable) {
      await _auth!.signOut();
    }
  }

  // Get current user data
  Future<User?> getCurrentUser() async {
    if (!isAvailable) return null;
    
    final firebaseUser = _auth!.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore!
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return User(
      id: firebaseUser.uid.hashCode,
      username: data['username'] ?? firebaseUser.displayName ?? 'User',
      email: firebaseUser.email!,
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'],
      uid: firebaseUser.uid,
    );
  }

  // Update user profile
  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    if (!isAvailable) return;
    
    final user = _auth!.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (username != null) {
      updates['username'] = username;
      await user.updateDisplayName(username);
    }
    if (avatarUrl != null) {
      updates['avatarUrl'] = avatarUrl;
    }

    if (updates.isNotEmpty) {
      await _firestore!.collection('users').doc(user.uid).update(updates);
    }
  }

  // Change password with verification
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (!isAvailable) return;
    
    final user = _auth!.currentUser;
    if (user == null || user.email == null) {
      throw 'Пайдаланушы табылмады';
    }
    
    // Reauthenticate with current password
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    
    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    if (!isAvailable) return;
    await _auth!.sendPasswordResetEmail(email: email);
  }

  String _mapFirebaseError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Бұл email тіркелген';
      case 'invalid-email':
        return 'Email қате форматта';
      case 'weak-password':
        return 'Құпия сөз тым қарапайым';
      case 'user-not-found':
        return 'Пайдаланушы табылмады';
      case 'wrong-password':
        return 'Құпия сөз қате';
      case 'user-disabled':
        return 'Аккаунт өшірілген';
      case 'too-many-requests':
        return 'Тым көп әрекет. Кейінірек қайталаңыз';
      default:
        return 'Қате орын алды: ${e.message}';
    }
  }
}
