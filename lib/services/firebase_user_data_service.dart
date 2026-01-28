import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../main.dart' show isFirebaseInitialized;

class FirebaseUserDataService {
  FirebaseFirestore? _firestore;
  
  FirebaseUserDataService() {
    if (isFirebaseInitialized) {
      try {
        _firestore = FirebaseFirestore.instance;
      } catch (e) {
        debugPrint('Firestore not available: $e');
        _firestore = null;
      }
    }
  }

  bool get isAvailable => _firestore != null;

  // Favorites
  CollectionReference<Map<String, dynamic>>? _favoritesRef(String userId) =>
      _firestore?.collection('users').doc(userId).collection('favorites');

  // Collections
  CollectionReference<Map<String, dynamic>>? _collectionsRef(String userId) =>
      _firestore?.collection('users').doc(userId).collection('collections');

  // Shopping list
  CollectionReference<Map<String, dynamic>>? _shoppingRef(String userId) =>
      _firestore?.collection('users').doc(userId).collection('shopping_list');

  // ========== FAVORITES ==========

  Future<List<int>> getFavoriteIds(String userId) async {
    if (!isAvailable) return [];
    final snapshot = await _favoritesRef(userId)!.get();
    return snapshot.docs.map((doc) => int.parse(doc.id)).toList();
  }

  Stream<List<int>> favoritesStream(String userId) {
    if (!isAvailable) return Stream.value([]);
    return _favoritesRef(userId)!.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => int.parse(doc.id)).toList());
  }

  Future<void> addFavorite(String userId, int recipeId) async {
    if (!isAvailable) return;
    await _favoritesRef(userId)!.doc(recipeId.toString()).set({
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String userId, int recipeId) async {
    if (!isAvailable) return;
    await _favoritesRef(userId)!.doc(recipeId.toString()).delete();
  }

  Future<bool> isFavorite(String userId, int recipeId) async {
    if (!isAvailable) return false;
    final doc = await _favoritesRef(userId)!.doc(recipeId.toString()).get();
    return doc.exists;
  }

  // ========== COLLECTIONS ==========

  Future<List<Collection>> getCollections(String userId) async {
    if (!isAvailable) return [];
    
    final snapshot = await _collectionsRef(userId)!
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Collection(
        id: doc.id.hashCode,
        firestoreId: doc.id,
        userId: userId.hashCode,
        name: data['name'] ?? '',
        description: data['description'],
        coverImageUrl: data['coverImageUrl'],
        recipeIds: List<int>.from(data['recipeIds'] ?? []),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Stream<List<Collection>> collectionsStream(String userId) {
    if (!isAvailable) return Stream.value([]);
    
    return _collectionsRef(userId)!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Collection(
                id: doc.id.hashCode,
                firestoreId: doc.id,
                userId: userId.hashCode,
                name: data['name'] ?? '',
                description: data['description'],
                coverImageUrl: data['coverImageUrl'],
                recipeIds: List<int>.from(data['recipeIds'] ?? []),
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  Future<Collection?> createCollection(String userId, String name,
      {String? description}) async {
    if (!isAvailable) return null;
    
    final docRef = await _collectionsRef(userId)!.add({
      'name': name,
      'description': description,
      'coverImageUrl': null,
      'recipeIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Collection(
      id: docRef.id.hashCode,
      firestoreId: docRef.id,
      userId: userId.hashCode,
      name: name,
      description: description,
      recipeIds: [],
      createdAt: DateTime.now(),
    );
  }

  Future<void> updateCollection(
      String userId, String collectionId, String name) async {
    if (!isAvailable) return;
    await _collectionsRef(userId)!.doc(collectionId).update({
      'name': name,
    });
  }

  Future<void> deleteCollection(String userId, String collectionId) async {
    if (!isAvailable) return;
    await _collectionsRef(userId)!.doc(collectionId).delete();
  }

  Future<void> addRecipeToCollection(
      String userId, String collectionId, int recipeId) async {
    if (!isAvailable) return;
    await _collectionsRef(userId)!.doc(collectionId).update({
      'recipeIds': FieldValue.arrayUnion([recipeId]),
    });
  }

  Future<void> removeRecipeFromCollection(
      String userId, String collectionId, int recipeId) async {
    if (!isAvailable) return;
    await _collectionsRef(userId)!.doc(collectionId).update({
      'recipeIds': FieldValue.arrayRemove([recipeId]),
    });
  }

  // ========== SHOPPING LIST ==========

  Future<List<ShoppingItem>> getShoppingList(String userId) async {
    if (!isAvailable) return [];
    
    final snapshot = await _shoppingRef(userId)!
        .orderBy('addedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ShoppingItem(
        id: doc.id.hashCode,
        firestoreId: doc.id,
        userId: userId.hashCode,
        ingredientId: data['ingredientId'],
        ingredientName: data['ingredientName'] ?? '',
        quantity: data['quantity'] ?? '',
        unit: data['unit'],
        recipeId: data['recipeId'],
        recipeName: data['recipeName'],
        isPurchased: data['isPurchased'] ?? false,
        addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Stream<List<ShoppingItem>> shoppingListStream(String userId) {
    if (!isAvailable) return Stream.value([]);
    
    return _shoppingRef(userId)!
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return ShoppingItem(
                id: doc.id.hashCode,
                firestoreId: doc.id,
                userId: userId.hashCode,
                ingredientId: data['ingredientId'],
                ingredientName: data['ingredientName'] ?? '',
                quantity: data['quantity'] ?? '',
                unit: data['unit'],
                recipeId: data['recipeId'],
                recipeName: data['recipeName'],
                isPurchased: data['isPurchased'] ?? false,
                addedAt:
                    (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }

  Future<ShoppingItem?> addShoppingItem(
    String userId, {
    required String ingredientName,
    required String quantity,
    String? unit,
    int? recipeId,
    String? recipeName,
  }) async {
    if (!isAvailable) return null;
    
    final docRef = await _shoppingRef(userId)!.add({
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'isPurchased': false,
      'addedAt': FieldValue.serverTimestamp(),
    });

    return ShoppingItem(
      id: docRef.id.hashCode,
      firestoreId: docRef.id,
      userId: userId.hashCode,
      ingredientName: ingredientName,
      quantity: quantity,
      unit: unit,
      recipeId: recipeId,
      recipeName: recipeName,
      isPurchased: false,
      addedAt: DateTime.now(),
    );
  }

  Future<void> toggleShoppingItem(
      String userId, String itemId, bool isPurchased) async {
    if (!isAvailable) return;
    await _shoppingRef(userId)!.doc(itemId).update({
      'isPurchased': isPurchased,
    });
  }

  Future<void> deleteShoppingItem(String userId, String itemId) async {
    if (!isAvailable) return;
    await _shoppingRef(userId)!.doc(itemId).delete();
  }

  Future<void> clearPurchasedItems(String userId) async {
    if (!isAvailable) return;
    
    final snapshot =
        await _shoppingRef(userId)!.where('isPurchased', isEqualTo: true).get();

    final batch = _firestore!.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> clearAllShoppingItems(String userId) async {
    if (!isAvailable) return;
    
    final snapshot = await _shoppingRef(userId)!.get();

    final batch = _firestore!.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
