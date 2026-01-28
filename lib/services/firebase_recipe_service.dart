import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';
import '../main.dart' show isFirebaseInitialized;

class FirebaseRecipeService {
  FirebaseFirestore? _firestore;
  
  FirebaseRecipeService() {
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

  CollectionReference<Map<String, dynamic>>? get _recipesRef =>
      _firestore?.collection('recipes');

  CollectionReference<Map<String, dynamic>>? get _categoriesRef =>
      _firestore?.collection('categories');

  // Get all recipes
  Stream<List<Recipe>> recipesStream() {
    if (!isAvailable) {
      return Stream.value(_getMockRecipes());
    }
    return _recipesRef!
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _recipeFromFirestore(doc))
            .toList());
  }

  // Get recipes list (one-time)
  Future<List<Recipe>> getRecipes({int limit = 20}) async {
    if (!isAvailable) {
      return _getMockRecipes();
    }
    
    final snapshot = await _recipesRef!
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => _recipeFromFirestore(doc)).toList();
  }

  // Get single recipe
  Future<Recipe?> getRecipe(String id) async {
    if (!isAvailable) return null;
    
    final doc = await _recipesRef!.doc(id).get();
    if (!doc.exists) return null;
    return _recipeFromFirestore(doc);
  }

  // Get recipes by category
  Future<List<Recipe>> getRecipesByCategory(int categoryId) async {
    if (!isAvailable) {
      return _getMockRecipes().where((r) => r.categoryId == categoryId).toList();
    }
    
    final snapshot = await _recipesRef!
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _recipeFromFirestore(doc)).toList();
  }

  // Get user recipes
  Future<List<Recipe>> getUserRecipes(String userId) async {
    if (!isAvailable) return [];
    
    final snapshot = await _recipesRef!
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => _recipeFromFirestore(doc)).toList();
  }

  // Search recipes
  Future<List<Recipe>> searchRecipes(String query) async {
    final queryLower = query.toLowerCase();
    
    if (!isAvailable) {
      return _getMockRecipes()
          .where((recipe) =>
              recipe.title.toLowerCase().contains(queryLower) ||
              (recipe.description?.toLowerCase().contains(queryLower) ?? false))
          .toList();
    }
    
    // Note: Firestore doesn't support full-text search natively
    // For production, use Algolia or similar
    final snapshot = await _recipesRef!.get();
    
    return snapshot.docs
        .map((doc) => _recipeFromFirestore(doc))
        .where((recipe) =>
            recipe.title.toLowerCase().contains(queryLower) ||
            (recipe.description?.toLowerCase().contains(queryLower) ?? false) ||
            recipe.ingredients.any((i) => i.name.toLowerCase().contains(queryLower)))
        .toList();
  }

  // Create recipe
  Future<Recipe> createRecipe(Recipe recipe, String userId, {String? authorName}) async {
    if (!isAvailable) {
      throw Exception('Firebase қолжетімсіз');
    }
    
    final docRef = await _recipesRef!.add({
      'userId': userId,
      'authorId': userId,
      'authorName': authorName,
      'title': recipe.title,
      'description': recipe.description,
      'cookingTime': recipe.cookingTime,
      'difficulty': recipe.difficulty,
      'categoryId': recipe.categoryId,
      'imageUrl': recipe.imageUrl,
      'servings': recipe.servings,
      'isVegetarian': recipe.isVegetarian,
      'isDietary': recipe.isDietary,
      'ingredients': recipe.ingredients.map((i) => {
        'ingredientId': i.ingredientId,
        'name': i.name,
        'quantity': i.quantity,
        'unit': i.unit,
        'notes': i.notes,
      }).toList(),
      'steps': recipe.steps.map((s) => {
        'stepNumber': s.stepNumber,
        'description': s.description,
        'imageUrl': s.imageUrl,
        'duration': s.duration,
      }).toList(),
      'rating': 0.0,
      'ratingCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return recipe.copyWith(id: docRef.id.hashCode, authorName: authorName, authorId: userId, firestoreId: docRef.id);
  }

  // Update recipe
  Future<Recipe> updateRecipe(String id, Recipe recipe) async {
    if (!isAvailable) {
      throw Exception('Firebase қолжетімсіз');
    }
    
    await _recipesRef!.doc(id).update({
      'title': recipe.title,
      'description': recipe.description,
      'cookingTime': recipe.cookingTime,
      'difficulty': recipe.difficulty,
      'categoryId': recipe.categoryId,
      'imageUrl': recipe.imageUrl,
      'servings': recipe.servings,
      'isVegetarian': recipe.isVegetarian,
      'isDietary': recipe.isDietary,
      'ingredients': recipe.ingredients.map((i) => {
        'ingredientId': i.ingredientId,
        'name': i.name,
        'quantity': i.quantity,
        'unit': i.unit,
        'notes': i.notes,
      }).toList(),
      'steps': recipe.steps.map((s) => {
        'stepNumber': s.stepNumber,
        'description': s.description,
        'imageUrl': s.imageUrl,
        'duration': s.duration,
      }).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return recipe;
  }

  // Delete recipe
  Future<void> deleteRecipe(String id) async {
    if (!isAvailable) return;
    await _recipesRef!.doc(id).delete();
  }

  // Rate recipe
  Future<void> rateRecipe(String recipeId, String oderId, int rating) async {
    if (!isAvailable) return;
    
    final ratingDoc = _recipesRef!.doc(recipeId).collection('ratings').doc(oderId);
    
    await _firestore!.runTransaction((transaction) async {
      final recipeDoc = await transaction.get(_recipesRef!.doc(recipeId));
      final currentRating = (recipeDoc.data()?['rating'] ?? 0.0) as double;
      final currentCount = (recipeDoc.data()?['ratingCount'] ?? 0) as int;

      final existingRating = await ratingDoc.get();
      
      double newRating;
      int newCount;
      
      if (existingRating.exists) {
        final oldRating = existingRating.data()?['rating'] ?? 0;
        newRating = ((currentRating * currentCount) - oldRating + rating) / currentCount;
        newCount = currentCount;
      } else {
        newRating = ((currentRating * currentCount) + rating) / (currentCount + 1);
        newCount = currentCount + 1;
      }

      transaction.update(_recipesRef!.doc(recipeId), {
        'rating': newRating,
        'ratingCount': newCount,
      });

      transaction.set(ratingDoc, {
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get user's rating for a recipe
  Future<int?> getUserRating(String recipeId, String userId) async {
    if (!isAvailable) return null;
    
    final doc = await _recipesRef!.doc(recipeId).collection('ratings').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data()?['rating'] as int?;
  }

  // Save user note for recipe
  Future<void> saveUserNote(String userId, String recipeId, String note) async {
    if (!isAvailable) return;
    
    await _firestore!
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(recipeId)
        .set({
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user note for recipe
  Future<String?> getUserNote(String userId, String recipeId) async {
    if (!isAvailable) return null;
    
    final doc = await _firestore!
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(recipeId)
        .get();
        
    if (!doc.exists) return null;
    return doc.data()?['note'] as String?;
  }

  // Get categories
  Future<List<Category>> getCategories() async {
    if (!isAvailable) {
      return Category.defaultCategories;
    }
    
    final snapshot = await _categoriesRef!.orderBy('order').get();
    
    if (snapshot.docs.isEmpty) {
      // Return default categories if none exist
      return Category.defaultCategories;
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Category(
        id: doc.id.hashCode,
        name: data['name'] ?? '',
        nameKk: data['nameKk'] ?? data['name'] ?? '',
        icon: data['icon'] ?? 'restaurant',
        color: data['color'] ?? '#FF6B35',
      );
    }).toList();
  }

  // Helper: Convert Firestore document to Recipe
  Recipe _recipeFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return Recipe(
      id: doc.id.hashCode,
      firestoreId: doc.id,
      userId: (data['userId'] as String?)?.hashCode ?? 0,
      title: data['title'] ?? '',
      description: data['description'],
      cookingTime: data['cookingTime'] ?? 0,
      difficulty: data['difficulty'] ?? 'medium',
      categoryId: data['categoryId'] ?? 1,
      imageUrl: data['imageUrl'],
      servings: data['servings'] ?? 4,
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      isVegetarian: data['isVegetarian'] ?? false,
      isDietary: data['isDietary'] ?? false,
      authorName: data['authorName'],
      authorId: data['authorId'] ?? data['userId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ingredients: (data['ingredients'] as List<dynamic>?)
          ?.map((i) => RecipeIngredient(
                ingredientId: i['ingredientId'] ?? 0,
                name: i['name'] ?? '',
                quantity: (i['quantity'] ?? 0).toDouble(),
                unit: i['unit'] ?? '',
                notes: i['notes'],
              ))
          .toList() ?? [],
      steps: (data['steps'] as List<dynamic>?)
          ?.map((s) => RecipeStep(
                stepNumber: s['stepNumber'] ?? 1,
                description: s['description'] ?? '',
                imageUrl: s['imageUrl'],
                duration: s['duration'],
              ))
          .toList() ?? [],
    );
  }

  // Mock recipes for offline mode
  List<Recipe> _getMockRecipes() {
    return [
      Recipe(
        id: 1,
        userId: 1,
        title: 'Бешбармақ',
        description: 'Қазақтың ұлттық тағамы',
        cookingTime: 120,
        difficulty: 'medium',
        categoryId: 2,
        servings: 6,
        rating: 4.8,
        ratingCount: 150,
        createdAt: DateTime.now(),
        ingredients: [
          RecipeIngredient(ingredientId: 1, name: 'Ет', quantity: 1, unit: 'кг'),
          RecipeIngredient(ingredientId: 2, name: 'Ұн', quantity: 500, unit: 'г'),
          RecipeIngredient(ingredientId: 3, name: 'Пияз', quantity: 2, unit: 'дана'),
        ],
        steps: [
          RecipeStep(stepNumber: 1, description: 'Етті қазанға салып, суға қайнатыңыз'),
          RecipeStep(stepNumber: 2, description: 'Қамыр жасап, жайып кесіңіз'),
          RecipeStep(stepNumber: 3, description: 'Қамырды сорпада пісіріңіз'),
        ],
      ),
      Recipe(
        id: 2,
        userId: 1,
        title: 'Қуырдақ',
        description: 'Дәстүрлі қазақ тағамы',
        cookingTime: 45,
        difficulty: 'easy',
        categoryId: 2,
        servings: 4,
        rating: 4.5,
        ratingCount: 80,
        createdAt: DateTime.now(),
        ingredients: [
          RecipeIngredient(ingredientId: 1, name: 'Ет', quantity: 500, unit: 'г'),
          RecipeIngredient(ingredientId: 2, name: 'Пияз', quantity: 2, unit: 'дана'),
          RecipeIngredient(ingredientId: 3, name: 'Май', quantity: 50, unit: 'г'),
        ],
        steps: [
          RecipeStep(stepNumber: 1, description: 'Етті ұсақ турап алыңыз'),
          RecipeStep(stepNumber: 2, description: 'Майда қуырыңыз'),
          RecipeStep(stepNumber: 3, description: 'Пияз қосып, піскенше қуырыңыз'),
        ],
      ),
      Recipe(
        id: 3,
        userId: 1,
        title: 'Баурсақ',
        description: 'Қазақтың дәстүрлі нан өнімі',
        cookingTime: 60,
        difficulty: 'easy',
        categoryId: 5,
        servings: 20,
        rating: 4.9,
        ratingCount: 200,
        createdAt: DateTime.now(),
        ingredients: [
          RecipeIngredient(ingredientId: 1, name: 'Ұн', quantity: 1, unit: 'кг'),
          RecipeIngredient(ingredientId: 2, name: 'Сүт', quantity: 500, unit: 'мл'),
          RecipeIngredient(ingredientId: 3, name: 'Ашытқы', quantity: 1, unit: 'пакет'),
        ],
        steps: [
          RecipeStep(stepNumber: 1, description: 'Қамыр илеңіз'),
          RecipeStep(stepNumber: 2, description: '30 минут ашытыңыз'),
          RecipeStep(stepNumber: 3, description: 'Майда қуырыңыз'),
        ],
      ),
    ];
  }
}

// Helper extension
extension RecipeCopyWith on Recipe {
  Recipe copyWith({int? id}) {
    return Recipe(
      id: id ?? this.id,
      firestoreId: firestoreId,
      userId: userId,
      title: title,
      description: description,
      cookingTime: cookingTime,
      difficulty: difficulty,
      categoryId: categoryId,
      imageUrl: imageUrl,
      servings: servings,
      rating: rating,
      ratingCount: ratingCount,
      isVegetarian: isVegetarian,
      isDietary: isDietary,
      authorName: authorName,
      createdAt: createdAt,
      ingredients: ingredients,
      steps: steps,
    );
  }
}
