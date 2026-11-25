class CustomCategory {
  final String id;
  final String name;
  final DateTime createdAt;

  const CustomCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  CustomCategory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
