import '../models/recipe.dart';
import '../models/category.dart';
import 'api_service.dart';

class RecipeFilters {
  final int? categoryId;
  final String? difficulty;
  final int? maxCookingTime;
  final bool? isVegetarian;
  final bool? isDietary;
  final String? sortBy;
  final bool ascending;

  RecipeFilters({
    this.categoryId,
    this.difficulty,
    this.maxCookingTime,
    this.isVegetarian,
    this.isDietary,
    this.sortBy,
    this.ascending = true,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (categoryId != null) params['category_id'] = categoryId;
    if (difficulty != null) params['difficulty'] = difficulty;
    if (maxCookingTime != null) params['max_cooking_time'] = maxCookingTime;
    if (isVegetarian != null) params['is_vegetarian'] = isVegetarian;
    if (isDietary != null) params['is_dietary'] = isDietary;
    if (sortBy != null) {
      params['sort_by'] = sortBy;
      params['sort_order'] = ascending ? 'asc' : 'desc';
    }
    return params;
  }
}

class RecipeService {
  final ApiService _api = ApiService();

  // Get all recipes with optional filters
  Future<List<Recipe>> getRecipes({
    int page = 1,
    int limit = 20,
    RecipeFilters? filters,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        ...?filters?.toQueryParams(),
      };
      
      final response = await _api.get('/recipes', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final recipes = (data['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      return recipes;
    } catch (e) {
      throw Exception('Рецепттерді жүктеу сәтсіз аяқталды');
    }
  }

  // Get single recipe by ID
  Future<Recipe> getRecipe(int id) async {
    try {
      final response = await _api.get('/recipes/$id');
      return Recipe.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Рецептті жүктеу сәтсіз аяқталды');
    }
  }

  // Create new recipe
  Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      final response = await _api.post('/recipes', data: recipe.toJson());
      return Recipe.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Рецепт қосу сәтсіз аяқталды');
    }
  }

  // Update recipe
  Future<Recipe> updateRecipe(Recipe recipe) async {
    try {
      final response = await _api.put('/recipes/${recipe.id}', data: recipe.toJson());
      return Recipe.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Рецептті жаңарту сәтсіз аяқталды');
    }
  }

  // Delete recipe
  Future<void> deleteRecipe(int id) async {
    try {
      await _api.delete('/recipes/$id');
    } catch (e) {
      throw Exception('Рецептті жою сәтсіз аяқталды');
    }
  }

  // Search recipes
  Future<List<Recipe>> searchRecipes({
    String? query,
    List<String>? ingredients,
    RecipeFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null) queryParams['q'] = query;
      if (ingredients != null && ingredients.isNotEmpty) {
        queryParams['ingredients'] = ingredients.join(',');
      }
      if (filters != null) {
        queryParams.addAll(filters.toQueryParams());
      }
      
      final response = await _api.get('/search', queryParameters: queryParams);
      final data = response.data as Map<String, dynamic>;
      final recipes = (data['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      return recipes;
    } catch (e) {
      throw Exception('Іздеу сәтсіз аяқталды');
    }
  }

  // Get user's recipes
  Future<List<Recipe>> getUserRecipes(int userId) async {
    try {
      final response = await _api.get('/users/$userId/recipes');
      final data = response.data as Map<String, dynamic>;
      final recipes = (data['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      return recipes;
    } catch (e) {
      throw Exception('Рецепттерді жүктеу сәтсіз аяқталды');
    }
  }

  // Rate recipe
  Future<void> rateRecipe(int recipeId, int rating) async {
    try {
      await _api.post('/recipes/$recipeId/rate', data: {'rating': rating});
    } catch (e) {
      throw Exception('Бағалау сәтсіз аяқталды');
    }
  }

  // Get categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _api.get('/categories');
      final data = response.data as List<dynamic>;
      return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // Return default categories if API fails
      return Category.defaultCategories;
    }
  }

  // Add note to recipe
  Future<void> addNote(int recipeId, String note) async {
    try {
      await _api.post('/recipes/$recipeId/notes', data: {'note': note});
    } catch (e) {
      throw Exception('Жазба қосу сәтсіз аяқталды');
    }
  }

  // Get recipe notes
  Future<List<Map<String, dynamic>>> getNotes(int recipeId) async {
    try {
      final response = await _api.get('/recipes/$recipeId/notes');
      return (response.data as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
