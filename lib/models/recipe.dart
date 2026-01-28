import 'ingredient.dart';

enum Difficulty {
  easy,
  medium,
  hard;

  String get nameKk {
    switch (this) {
      case Difficulty.easy:
        return 'Оңай';
      case Difficulty.medium:
        return 'Орташа';
      case Difficulty.hard:
        return 'Қиын';
    }
  }

  static Difficulty fromString(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return Difficulty.easy;
      case 'medium':
        return Difficulty.medium;
      case 'hard':
        return Difficulty.hard;
      default:
        return Difficulty.medium;
    }
  }
}

class RecipeStep {
  final int stepNumber;
  final String description;
  final String? imageUrl;
  final int? duration; // in minutes

  RecipeStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
    this.duration,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'] as int,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      duration: json['duration'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_number': stepNumber,
      'description': description,
      'image_url': imageUrl,
      'duration': duration,
    };
  }

  RecipeStep copyWith({
    int? stepNumber,
    String? description,
    String? imageUrl,
    int? duration,
  }) {
    return RecipeStep(
      stepNumber: stepNumber ?? this.stepNumber,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      duration: duration ?? this.duration,
    );
  }
}

class Recipe {
  final int id;
  final String? firestoreId; // Firestore document ID
  final int userId;
  final String title;
  final String? description;
  final int cookingTime;
  final String difficulty;
  final int categoryId;
  final String? categoryName;
  final String? imageUrl;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final bool isFavorite;
  final int? userRating;
  final String? authorName;
  final String? authorId;
  final int servings;
  final bool isVegetarian;
  final bool isDietary;

  Recipe({
    required this.id,
    this.firestoreId,
    required this.userId,
    required this.title,
    this.description,
    required this.cookingTime,
    required this.difficulty,
    required this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.rating = 0,
    this.ratingCount = 0,
    required this.createdAt,
    this.ingredients = const [],
    this.steps = const [],
    this.isFavorite = false,
    this.userRating,
    this.authorName,
    this.authorId,
    this.servings = 4,
    this.isVegetarian = false,
    this.isDietary = false,
  });

  Difficulty get difficultyLevel => Difficulty.fromString(difficulty);

  String get formattedCookingTime {
    if (cookingTime < 60) {
      return '$cookingTime мин';
    } else {
      final hours = cookingTime ~/ 60;
      final minutes = cookingTime % 60;
      if (minutes == 0) {
        return '$hours сағ';
      }
      return '$hours сағ $minutes мин';
    }
  }

  bool get isQuick => cookingTime <= 30;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      firestoreId: json['firestore_id'] as String?,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      cookingTime: json['cooking_time'] as int,
      difficulty: json['difficulty'] as String,
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String?,
      imageUrl: json['image_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isFavorite: json['is_favorite'] as bool? ?? false,
      userRating: json['user_rating'] as int?,
      authorName: json['author_name'] as String?,
      servings: json['servings'] as int? ?? 4,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isDietary: json['is_dietary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firestore_id': firestoreId,
      'user_id': userId,
      'title': title,
      'description': description,
      'cooking_time': cookingTime,
      'difficulty': difficulty,
      'category_id': categoryId,
      'category_name': categoryName,
      'image_url': imageUrl,
      'rating': rating,
      'rating_count': ratingCount,
      'created_at': createdAt.toIso8601String(),
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
      'is_favorite': isFavorite,
      'user_rating': userRating,
      'author_name': authorName,
      'servings': servings,
      'is_vegetarian': isVegetarian,
      'is_dietary': isDietary,
    };
  }

  Recipe copyWith({
    int? id,
    String? firestoreId,
    int? userId,
    String? title,
    String? description,
    int? cookingTime,
    String? difficulty,
    int? categoryId,
    String? categoryName,
    String? imageUrl,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
    bool? isFavorite,
    int? userRating,
    String? authorName,
    String? authorId,
    int? servings,
    bool? isVegetarian,
    bool? isDietary,
  }) {
    return Recipe(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      cookingTime: cookingTime ?? this.cookingTime,
      difficulty: difficulty ?? this.difficulty,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      isFavorite: isFavorite ?? this.isFavorite,
      userRating: userRating ?? this.userRating,
      authorName: authorName ?? this.authorName,
      authorId: authorId ?? this.authorId,
      servings: servings ?? this.servings,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isDietary: isDietary ?? this.isDietary,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, cookingTime: $cookingTime min)';
  }
}
