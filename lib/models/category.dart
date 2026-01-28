class Category {
  final int id;
  final String name;
  final String nameKk;
  final String icon;
  final String color;

  Category({
    required this.id,
    required this.name,
    required this.nameKk,
    required this.icon,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      nameKk: json['name_kk'] as String? ?? json['name'] as String,
      icon: json['icon'] as String? ?? 'restaurant',
      color: json['color'] as String? ?? '#FF6B35',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_kk': nameKk,
      'icon': icon,
      'color': color,
    };
  }

  // Default categories
  static List<Category> defaultCategories = [
    Category(id: 1, name: 'breakfast', nameKk: 'Таңғы ас', icon: 'breakfast_dining', color: '#FFB74D'),
    Category(id: 2, name: 'lunch', nameKk: 'Түскі ас', icon: 'lunch_dining', color: '#4CAF50'),
    Category(id: 3, name: 'dinner', nameKk: 'Кешкі ас', icon: 'dinner_dining', color: '#7E57C2'),
    Category(id: 4, name: 'dessert', nameKk: 'Десерттер', icon: 'cake', color: '#EC407A'),
    Category(id: 5, name: 'snack', nameKk: 'Снектер', icon: 'fastfood', color: '#FF7043'),
    Category(id: 6, name: 'soup', nameKk: 'Сорпалар', icon: 'soup_kitchen', color: '#26A69A'),
    Category(id: 7, name: 'salad', nameKk: 'Салаттар', icon: 'eco', color: '#66BB6A'),
    Category(id: 8, name: 'drink', nameKk: 'Сусындар', icon: 'local_cafe', color: '#42A5F5'),
    Category(id: 9, name: 'bakery', nameKk: 'Наубайхана', icon: 'bakery_dining', color: '#FFAB91'),
    Category(id: 10, name: 'national', nameKk: 'Ұлттық тағамдар', icon: 'restaurant', color: '#FF6B35'),
  ];
}
