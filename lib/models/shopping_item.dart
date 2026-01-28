class ShoppingItem {
  final int id;
  final String? firestoreId;
  final int userId;
  final int? ingredientId;
  final String ingredientName;
  final String quantity;
  final String? unit;
  final int? recipeId;
  final String? recipeName;
  final bool isPurchased;
  final DateTime addedAt;

  ShoppingItem({
    required this.id,
    this.firestoreId,
    required this.userId,
    this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    this.unit,
    this.recipeId,
    this.recipeName,
    this.isPurchased = false,
    required this.addedAt,
  });

  String get displayQuantity {
    if (unit != null && unit!.isNotEmpty) {
      return '$quantity $unit';
    }
    return quantity;
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as int,
      firestoreId: json['firestore_id'] as String?,
      userId: json['user_id'] as int,
      ingredientId: json['ingredient_id'] as int?,
      ingredientName: json['ingredient_name'] as String,
      quantity: json['quantity'] as String,
      unit: json['unit'] as String?,
      recipeId: json['recipe_id'] as int?,
      recipeName: json['recipe_name'] as String?,
      isPurchased: json['is_purchased'] as bool? ?? false,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firestore_id': firestoreId,
      'user_id': userId,
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'is_purchased': isPurchased,
      'added_at': addedAt.toIso8601String(),
    };
  }

  ShoppingItem copyWith({
    int? id,
    String? firestoreId,
    int? userId,
    int? ingredientId,
    String? ingredientName,
    String? quantity,
    String? unit,
    int? recipeId,
    String? recipeName,
    bool? isPurchased,
    DateTime? addedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      isPurchased: isPurchased ?? this.isPurchased,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
