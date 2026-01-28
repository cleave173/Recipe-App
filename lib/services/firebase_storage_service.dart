import 'dart:io';
import 'package:flutter/foundation.dart';
import '../main.dart' show isFirebaseInitialized;

// Conditionally import firebase_storage
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  FirebaseStorage? _storage;
  final _uuid = const Uuid();
  
  // Flag to track if Storage is available
  bool _isStorageAvailable = false;

  FirebaseStorageService() {
    _initStorage();
  }

  void _initStorage() {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase not initialized - Storage disabled');
      return;
    }
    
    try {
      _storage = FirebaseStorage.instance;
      _isStorageAvailable = true;
      debugPrint('Firebase Storage initialized');
    } catch (e) {
      debugPrint('Firebase Storage not available: $e');
      debugPrint('Running without Storage - images will use URLs only');
      _isStorageAvailable = false;
    }
  }

  bool get isAvailable => _isStorageAvailable && _storage != null;

  // Upload recipe image
  Future<String?> uploadRecipeImage(File imageFile, {String? recipeId}) async {
    if (!isAvailable) {
      debugPrint('Storage not available - cannot upload image');
      return null;
    }
    
    try {
      final fileName = recipeId ?? _uuid.v4();
      final ref = _storage!.ref().child('recipes/$fileName.jpg');
      
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading recipe image: $e');
      return null;
    }
  }

  // Upload step image
  Future<String?> uploadStepImage(
    File imageFile, {
    required String recipeId,
    required int stepNumber,
  }) async {
    if (!isAvailable) {
      debugPrint('Storage not available - cannot upload step image');
      return null;
    }
    
    try {
      final ref = _storage!
          .ref()
          .child('recipes/$recipeId/steps/step_$stepNumber.jpg');
      
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading step image: $e');
      return null;
    }
  }

  // Upload user avatar
  Future<String?> uploadAvatar(File imageFile, String userId) async {
    if (!isAvailable) {
      debugPrint('Storage not available - cannot upload avatar');
      return null;
    }
    
    try {
      final ref = _storage!.ref().child('avatars/$userId.jpg');
      
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // Upload collection cover
  Future<String?> uploadCollectionCover(
    File imageFile, 
    String userId,
    String collectionId,
  ) async {
    if (!isAvailable) {
      debugPrint('Storage not available - cannot upload collection cover');
      return null;
    }
    
    try {
      final ref = _storage!
          .ref()
          .child('users/$userId/collections/$collectionId.jpg');
      
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading collection cover: $e');
      return null;
    }
  }

  // Delete image by URL
  Future<void> deleteImage(String imageUrl) async {
    if (!isAvailable) return;
    
    try {
      final ref = _storage!.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  // Delete all recipe images (main + steps)
  Future<void> deleteRecipeImages(String recipeId) async {
    if (!isAvailable) return;
    
    try {
      // Delete main image
      try {
        await _storage!.ref().child('recipes/$recipeId.jpg').delete();
      } catch (_) {}

      // Delete step images folder
      final stepsRef = _storage!.ref().child('recipes/$recipeId/steps');
      final listResult = await stepsRef.listAll();
      
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Error deleting recipe images: $e');
    }
  }
}
