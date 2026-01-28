class Ingredient {
  final int id;
  final String name;
  final String? nameKk;

  Ingredient({
    required this.id,
    required this.name,
    this.nameKk,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      nameKk: json['name_kk'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_kk': nameKk,
    };
  }
}

class MeasurementUnit {
  static const String gram = 'грамм';
  static const String kilogram = 'келі';
  static const String milliliter = 'мл';
  static const String liter = 'литр';
  static const String tablespoon = 'ас қас';
  static const String teaspoon = 'шай қас';
  static const String piece = 'дана';
  static const String pinch = 'шымшым';
  static const String cup = 'стакан';
  static const String bunch = 'байлам';

  static const List<String> all = [
    gram,
    kilogram,
    milliliter,
    liter,
    tablespoon,
    teaspoon,
    piece,
    pinch,
    cup,
    bunch,
  ];
}

class RecipeIngredient {
  final int ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final String? notes;
  final bool isPurchased;

  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
    this.isPurchased = false,
  });

  String get formattedQuantity {
    if (quantity == quantity.roundToDouble()) {
      return '${quantity.toInt()} $unit';
    }
    return '${quantity.toStringAsFixed(1)} $unit';
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredient_id'] as int? ?? 0,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      notes: json['notes'] as String?,
      isPurchased: json['is_purchased'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'is_purchased': isPurchased,
    };
  }

  RecipeIngredient copyWith({
    int? ingredientId,
    String? name,
    double? quantity,
    String? unit,
    String? notes,
    bool? isPurchased,
  }) {
    return RecipeIngredient(
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
