import 'package:flutter/foundation.dart' hide Category;
import '../models/models.dart';
import '../services/firebase_recipe_service.dart';
import '../services/firebase_user_data_service.dart';

class RecipeProvider extends ChangeNotifier {
  final FirebaseRecipeService _recipeService = FirebaseRecipeService();
  final FirebaseUserDataService _userDataService = FirebaseUserDataService();

  List<Recipe> _recipes = [];
  List<Recipe> _searchResults = [];
  List<Category> _categories = [];
  Set<int> _favoriteIds = {};
  Recipe? _selectedRecipe;
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Recipe> get recipes => _recipes;
  List<Recipe> get searchResults => _searchResults;
  List<Category> get categories => _categories;
  Recipe? get selectedRecipe => _selectedRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Recipe> get favoriteRecipes =>
      _recipes.where((r) => _favoriteIds.contains(r.id)).toList();

  List<Recipe> get quickRecipes =>
      _recipes.where((r) => r.isQuick).toList();

  void setUserId(String? userId) {
    _userId = userId;
    if (userId != null) {
      _loadFavorites();
    }
  }

  Future<void> init() async {
    await loadCategories();
    await loadRecipes();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _recipeService.getCategories();
      notifyListeners();
    } catch (e) {
      _categories = Category.defaultCategories;
      notifyListeners();
    }
  }

  Future<void> loadRecipes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recipes = await _recipeService.getRecipes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Рецепттерді жүктеу кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<Recipe?> loadRecipe(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Find in local cache first
      final localRecipe = _recipes.firstWhere(
        (r) => r.id == id,
        orElse: () => Recipe(
          id: 0,
          userId: 0,
          title: '',
          cookingTime: 0,
          difficulty: 'medium',
          categoryId: 1,
          createdAt: DateTime.now(),
        ),
      );

      if (localRecipe.id != 0) {
        _selectedRecipe = localRecipe;
        _isLoading = false;
        notifyListeners();
        return localRecipe;
      }

      // Load from Firestore if not found
      final firestoreRecipe = _recipes.firstWhere(
        (r) => r.id == id,
        orElse: () => Recipe(
          id: 0,
          userId: 0,
          title: '',
          cookingTime: 0,
          difficulty: 'medium',
          categoryId: 1,
          createdAt: DateTime.now(),
        ),
      );

      _selectedRecipe = firestoreRecipe.id != 0 ? firestoreRecipe : null;
      _isLoading = false;
      notifyListeners();
      return _selectedRecipe;
    } catch (e) {
      _isLoading = false;
      _error = 'Рецептті жүктеу кезінде қате: $e';
      notifyListeners();
      return null;
    }
  }

  List<Recipe> getRecipesByCategory(int categoryId) {
    return _recipes.where((r) => r.categoryId == categoryId).toList();
  }

  Future<void> searchRecipes(String query, {RecipeFilters? filters}) async {
    if (query.isEmpty && filters == null) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      var results = await _recipeService.searchRecipes(query);

      // Apply filters
      if (filters != null) {
        if (filters.categoryId != null) {
          results = results.where((r) => r.categoryId == filters.categoryId).toList();
        }
        if (filters.difficulty != null) {
          results = results.where((r) => r.difficulty == filters.difficulty).toList();
        }
        if (filters.maxCookingTime != null) {
          results = results.where((r) => r.cookingTime <= filters.maxCookingTime!).toList();
        }
        if (filters.isVegetarian == true) {
          results = results.where((r) => r.isVegetarian).toList();
        }
        if (filters.isDietary == true) {
          results = results.where((r) => r.isDietary).toList();
        }

        // Sort
        if (filters.sortBy != null) {
          switch (filters.sortBy) {
            case 'cooking_time':
              results.sort((a, b) => a.cookingTime.compareTo(b.cookingTime));
              break;
            case 'rating':
              results.sort((a, b) => b.rating.compareTo(a.rating));
              break;
            case 'created_at':
              results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
          }
        }
      }

      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Іздеу кезінде қате: $e';
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  String? _userName;
  
  void setUserInfo(String? userId, String? userName) {
    _userId = userId;
    _userName = userName;
    if (userId != null) {
      _loadFavorites();
    }
  }

  // Get current user ID
  String? get currentUserId => _userId;

  // Get user's recipes
  Future<List<Recipe>> getUserRecipes() async {
    if (_userId == null) return [];
    
    try {
      return await _recipeService.getUserRecipes(_userId!);
    } catch (e) {
      debugPrint('Error loading user recipes: $e');
      return [];
    }
  }

  // Get user's rating for a recipe
  Future<int?> getUserRating(String? recipeFirestoreId) async {
    if (_userId == null || recipeFirestoreId == null) return null;
    
    try {
      return await _recipeService.getUserRating(recipeFirestoreId, _userId!);
    } catch (e) {
      debugPrint('Error loading user rating: $e');
      return null;
    }
  }

  Future<Recipe?> createRecipe(Recipe recipe) async {
    if (_userId == null) return null;

    try {
      final newRecipe = await _recipeService.createRecipe(recipe, _userId!, authorName: _userName);
      _recipes.insert(0, newRecipe);
      notifyListeners();
      return newRecipe;
    } catch (e) {
      _error = 'Рецептті қосу кезінде қате: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Recipe?> updateRecipe(Recipe recipe) async {
    if (recipe.firestoreId == null) return null;

    try {
      // Сохраняем authorId из оригинального рецепта
      final originalRecipe = _recipes.firstWhere(
        (r) => r.id == recipe.id,
        orElse: () => recipe,
      );
      
      final updatedRecipe = await _recipeService.updateRecipe(
        recipe.firestoreId!,
        recipe,
      );
      
      // Создаём рецепт с сохранёнными данными автора
      final recipeWithAuthor = Recipe(
        id: updatedRecipe.id,
        firestoreId: updatedRecipe.firestoreId ?? recipe.firestoreId,
        userId: originalRecipe.userId,
        authorId: originalRecipe.authorId,
        authorName: originalRecipe.authorName,
        title: updatedRecipe.title,
        description: updatedRecipe.description,
        cookingTime: updatedRecipe.cookingTime,
        difficulty: updatedRecipe.difficulty,
        categoryId: updatedRecipe.categoryId,
        imageUrl: updatedRecipe.imageUrl,
        servings: updatedRecipe.servings,
        createdAt: originalRecipe.createdAt,
        rating: originalRecipe.rating,
        ratingCount: originalRecipe.ratingCount,
        ingredients: updatedRecipe.ingredients,
        steps: updatedRecipe.steps,
        isVegetarian: updatedRecipe.isVegetarian,
        isDietary: updatedRecipe.isDietary,
      );
      
      final index = _recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _recipes[index] = recipeWithAuthor;
        notifyListeners();
      }
      return recipeWithAuthor;
    } catch (e) {
      _error = 'Рецептті жаңарту кезінде қате: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteRecipe(int id) async {
    final recipe = _recipes.firstWhere(
      (r) => r.id == id,
      orElse: () => Recipe(
        id: 0,
        userId: 0,
        title: '',
        cookingTime: 0,
        difficulty: 'medium',
        categoryId: 1,
        createdAt: DateTime.now(),
      ),
    );

    if (recipe.firestoreId == null) return false;

    try {
      await _recipeService.deleteRecipe(recipe.firestoreId!);
      _recipes.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Рецептті жою кезінде қате: $e';
      notifyListeners();
      return false;
    }
  }

  // Favorites
  Future<void> _loadFavorites() async {
    if (_userId == null) return;
    try {
      final ids = await _userDataService.getFavoriteIds(_userId!);
      _favoriteIds = Set.from(ids);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  bool isFavorite(int recipeId) => _favoriteIds.contains(recipeId);

  Future<void> toggleFavorite(int recipeId) async {
    if (_userId == null) return;

    try {
      if (_favoriteIds.contains(recipeId)) {
        _favoriteIds.remove(recipeId);
        await _userDataService.removeFavorite(_userId!, recipeId);
      } else {
        _favoriteIds.add(recipeId);
        await _userDataService.addFavorite(_userId!, recipeId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  // Rating
  Future<void> rateRecipe(int recipeId, int rating) async {
    if (_userId == null) return;

    final recipe = _recipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => Recipe(
        id: 0,
        userId: 0,
        title: '',
        cookingTime: 0,
        difficulty: 'medium',
        categoryId: 1,
        createdAt: DateTime.now(),
      ),
    );

    if (recipe.firestoreId == null) return;

    try {
      await _recipeService.rateRecipe(recipe.firestoreId!, _userId!, rating);
      // Refresh recipe to get updated rating
      await loadRecipes();
    } catch (e) {
      debugPrint('Error rating recipe: $e');
    }
  }
  Future<void> saveUserNote(String recipeId, String note) async {
    if (_userId == null) return;
    
    try {
      await _recipeService.saveUserNote(_userId!, recipeId, note);
    } catch (e) {
      debugPrint('Error saving user note: $e');
      rethrow;
    }
  }

  Future<String?> getUserNote(String recipeId) async {
    if (_userId == null) return null;
    
    try {
      return await _recipeService.getUserNote(_userId!, recipeId);
    } catch (e) {
      debugPrint('Error loading user note: $e');
      return null;
    }
  }
}

class RecipeFilters {
  final int? categoryId;
  final String? difficulty;
  final int? maxCookingTime;
  final bool? isVegetarian;
  final bool? isDietary;
  final String? sortBy;

  RecipeFilters({
    this.categoryId,
    this.difficulty,
    this.maxCookingTime,
    this.isVegetarian,
    this.isDietary,
    this.sortBy,
  });
}
