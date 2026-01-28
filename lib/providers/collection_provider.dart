import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firebase_user_data_service.dart';

class CollectionProvider extends ChangeNotifier {
  final FirebaseUserDataService _service = FirebaseUserDataService();

  List<Collection> _collections = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<Collection> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setUserId(String? userId) {
    _userId = userId;
    if (userId != null) {
      loadCollections();
    }
  }

  Future<void> loadCollections() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _collections = await _service.getCollections(_userId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Коллекцияларды жүктеу кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<Collection?> createCollection(String name, {String? description}) async {
    if (_userId == null) return null;

    try {
      final collection = await _service.createCollection(
        _userId!,
        name,
        description: description,
      );
      if (collection != null) {
        _collections.insert(0, collection);
      }
      notifyListeners();
      return collection;
    } catch (e) {
      _error = 'Коллекцияны құру кезінде қате: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteCollection(int id) async {
    if (_userId == null) return;

    final collection = _collections.firstWhere(
      (c) => c.id == id,
      orElse: () => Collection(
        id: 0,
        userId: 0,
        name: '',
        createdAt: DateTime.now(),
      ),
    );

    if (collection.firestoreId == null) return;

    try {
      await _service.deleteCollection(_userId!, collection.firestoreId!);
      _collections.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Коллекцияны жою кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> addRecipeToCollection(int collectionId, int recipeId) async {
    if (_userId == null) return;

    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => Collection(
        id: 0,
        userId: 0,
        name: '',
        createdAt: DateTime.now(),
      ),
    );

    if (collection.firestoreId == null) return;

    try {
      await _service.addRecipeToCollection(
        _userId!,
        collection.firestoreId!,
        recipeId,
      );
      
      final index = _collections.indexWhere((c) => c.id == collectionId);
      if (index != -1) {
        final updatedIds = List<int>.from(_collections[index].recipeIds)
          ..add(recipeId);
        _collections[index] = _collections[index].copyWith(recipeIds: updatedIds);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Рецептті қосу кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> removeRecipeFromCollection(int collectionId, int recipeId) async {
    if (_userId == null) return;

    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => Collection(
        id: 0,
        userId: 0,
        name: '',
        createdAt: DateTime.now(),
      ),
    );

    if (collection.firestoreId == null) return;

    try {
      await _service.removeRecipeFromCollection(
        _userId!,
        collection.firestoreId!,
        recipeId,
      );
      
      final index = _collections.indexWhere((c) => c.id == collectionId);
      if (index != -1) {
        final updatedIds = List<int>.from(_collections[index].recipeIds)
          ..remove(recipeId);
        _collections[index] = _collections[index].copyWith(recipeIds: updatedIds);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Рецептті жою кезінде қате: $e';
      notifyListeners();
    }
  }
}

class ShoppingListProvider extends ChangeNotifier {
  final FirebaseUserDataService _service = FirebaseUserDataService();

  List<ShoppingItem> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;

  List<ShoppingItem> get items => _items;
  List<ShoppingItem> get purchasedItems =>
      _items.where((i) => i.isPurchased).toList();
  List<ShoppingItem> get unpurchasedItems =>
      _items.where((i) => !i.isPurchased).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get purchasedCount => _items.where((i) => i.isPurchased).length;
  int get totalItems => _items.length;

  void setUserId(String? userId) {
    _userId = userId;
    if (userId != null) {
      loadItems();
    }
  }

  Future<void> loadItems() async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _service.getShoppingList(_userId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Тізімді жүктеу кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> addItem({
    required String ingredientName,
    required String quantity,
    String? unit,
    int? recipeId,
    String? recipeName,
  }) async {
    if (_userId == null) return;

    try {
      final item = await _service.addShoppingItem(
        _userId!,
        ingredientName: ingredientName,
        quantity: quantity,
        unit: unit,
        recipeId: recipeId,
        recipeName: recipeName,
      );
      if (item != null) {
        _items.insert(0, item);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Элементті қосу кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> addFromRecipe(int recipeId) async {
    // TODO: Load recipe and add all ingredients
    debugPrint('Adding ingredients from recipe $recipeId');
  }

  Future<void> togglePurchased(int id) async {
    if (_userId == null) return;

    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = _items[index];
    if (item.firestoreId == null) return;

    try {
      final newStatus = !item.isPurchased;
      await _service.toggleShoppingItem(_userId!, item.firestoreId!, newStatus);
      _items[index] = item.copyWith(isPurchased: newStatus);
      notifyListeners();
    } catch (e) {
      _error = 'Күйді өзгерту кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> deleteItem(int id) async {
    if (_userId == null) return;

    final item = _items.firstWhere(
      (i) => i.id == id,
      orElse: () => ShoppingItem(
        id: 0,
        userId: 0,
        ingredientName: '',
        quantity: '',
        addedAt: DateTime.now(),
      ),
    );

    if (item.firestoreId == null) return;

    try {
      await _service.deleteShoppingItem(_userId!, item.firestoreId!);
      _items.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Элементті жою кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> clearPurchased() async {
    if (_userId == null) return;

    try {
      await _service.clearPurchasedItems(_userId!);
      _items.removeWhere((i) => i.isPurchased);
      notifyListeners();
    } catch (e) {
      _error = 'Тізімді тазалау кезінде қате: $e';
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    if (_userId == null) return;

    try {
      await _service.clearAllShoppingItems(_userId!);
      _items.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Тізімді тазалау кезінде қате: $e';
      notifyListeners();
    }
  }
}
