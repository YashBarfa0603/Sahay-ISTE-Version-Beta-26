class CategoryModel {
  final String categoryId;
  final String name;
  final String? nameHindi;
  final String description;
  final String? descriptionHindi;
  final String iconName;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor
  const CategoryModel({
    required this.categoryId,
    required this.name,
    this.nameHindi,
    required this.description,
    this.descriptionHindi,
    required this.iconName,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'nameHindi': nameHindi,
      'description': description,
      'descriptionHindi': descriptionHindi,
      'iconName': iconName,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Deserialization
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['categoryId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameHindi: map['nameHindi'] as String?,
      description: map['description'] as String? ?? '',
      descriptionHindi: map['descriptionHindi'] as String?,
      iconName: map['iconName'] as String? ?? 'category',
      isActive: map['isActive'] as bool? ?? true,
      displayOrder: map['displayOrder'] as int? ?? 0,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  // Copy
  CategoryModel copyWith({
    String? name,
    String? nameHindi,
    String? description,
    String? descriptionHindi,
    String? iconName,
    bool? isActive,
    int? displayOrder,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      categoryId: categoryId,
      name: name ?? this.name,
      nameHindi: nameHindi ?? this.nameHindi,
      description: description ?? this.description,
      descriptionHindi: descriptionHindi ?? this.descriptionHindi,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
