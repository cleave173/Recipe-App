class Collection {
  final int id;
  final String? firestoreId;
  final int userId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final List<int> recipeIds;
  final DateTime createdAt;

  Collection({
    required this.id,
    this.firestoreId,
    required this.userId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.recipeIds = const [],
    required this.createdAt,
  });

  int get recipeCount => recipeIds.length;

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as int,
      firestoreId: json['firestore_id'] as String?,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      recipeIds: (json['recipe_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firestore_id': firestoreId,
      'user_id': userId,
      'name': name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'recipe_ids': recipeIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Collection copyWith({
    int? id,
    String? firestoreId,
    int? userId,
    String? name,
    String? description,
    String? coverImageUrl,
    List<int>? recipeIds,
    DateTime? createdAt,
  }) {
    return Collection(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      recipeIds: recipeIds ?? this.recipeIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
