import '../models/collection.dart';
import '../models/shopping_item.dart';
import 'api_service.dart';

class FavoritesService {
  final ApiService _api = ApiService();

  // Get favorites
  Future<List<int>> getFavoriteIds() async {
    try {
      final response = await _api.get('/favorites');
      final data = response.data as Map<String, dynamic>;
      return (data['recipe_ids'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Add to favorites
  Future<void> addToFavorites(int recipeId) async {
    try {
      await _api.post('/favorites/$recipeId');
    } catch (e) {
      throw Exception('Таңдаулыларға қосу сәтсіз аяқталды');
    }
  }

  // Remove from favorites
  Future<void> removeFromFavorites(int recipeId) async {
    try {
      await _api.delete('/favorites/$recipeId');
    } catch (e) {
      throw Exception('Таңдаулылардан алу сәтсіз аяқталды');
    }
  }
}

class CollectionService {
  final ApiService _api = ApiService();

  // Get all collections
  Future<List<Collection>> getCollections() async {
    try {
      final response = await _api.get('/collections');
      final data = response.data as List<dynamic>;
      return data.map((e) => Collection.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Жинақтарды жүктеу сәтсіз аяқталды');
    }
  }

  // Create collection
  Future<Collection> createCollection(String name) async {
    try {
      final response = await _api.post('/collections', data: {'name': name});
      return Collection.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Жинақ құру сәтсіз аяқталды');
    }
  }

  // Delete collection
  Future<void> deleteCollection(int id) async {
    try {
      await _api.delete('/collections/$id');
    } catch (e) {
      throw Exception('Жинақты жою сәтсіз аяқталды');
    }
  }

  // Add recipe to collection
  Future<void> addRecipeToCollection(int collectionId, int recipeId) async {
    try {
      await _api.post('/collections/$collectionId/recipes/$recipeId');
    } catch (e) {
      throw Exception('Жинаққа қосу сәтсіз аяқталды');
    }
  }

  // Remove recipe from collection
  Future<void> removeRecipeFromCollection(int collectionId, int recipeId) async {
    try {
      await _api.delete('/collections/$collectionId/recipes/$recipeId');
    } catch (e) {
      throw Exception('Жинақтан алу сәтсіз аяқталды');
    }
  }
}

class ShoppingListService {
  final ApiService _api = ApiService();

  // Get shopping list
  Future<List<ShoppingItem>> getShoppingList() async {
    try {
      final response = await _api.get('/shopping-list');
      final data = response.data as List<dynamic>;
      return data.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Тізімді жүктеу сәтсіз аяқталды');
    }
  }

  // Add item to shopping list
  Future<ShoppingItem> addItem({
    required String ingredientName,
    required String quantity,
    int? recipeId,
    String? recipeName,
  }) async {
    try {
      final response = await _api.post('/shopping-list', data: {
        'ingredient_name': ingredientName,
        'quantity': quantity,
        'recipe_id': recipeId,
        'recipe_name': recipeName,
      });
      return ShoppingItem.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Қосу сәтсіз аяқталды');
    }
  }

  // Add ingredients from recipe
  Future<void> addFromRecipe(int recipeId) async {
    try {
      await _api.post('/shopping-list/from-recipe/$recipeId');
    } catch (e) {
      throw Exception('Ингредиенттерді қосу сәтсіз аяқталды');
    }
  }

  // Toggle item purchased status
  Future<void> togglePurchased(int itemId, bool isPurchased) async {
    try {
      await _api.put('/shopping-list/$itemId', data: {
        'is_purchased': isPurchased,
      });
    } catch (e) {
      throw Exception('Жаңарту сәтсіз аяқталды');
    }
  }

  // Delete item
  Future<void> deleteItem(int itemId) async {
    try {
      await _api.delete('/shopping-list/$itemId');
    } catch (e) {
      throw Exception('Жою сәтсіз аяқталды');
    }
  }

  // Clear all purchased items
  Future<void> clearPurchased() async {
    try {
      await _api.delete('/shopping-list/purchased');
    } catch (e) {
      throw Exception('Тазалау сәтсіз аяқталды');
    }
  }

  // Clear entire list
  Future<void> clearAll() async {
    try {
      await _api.delete('/shopping-list');
    } catch (e) {
      throw Exception('Тазалау сәтсіз аяқталды');
    }
  }
}
