
class CategoryRule {
  final String id;
  final String rulePattern; // The keyword or phrase to match
  final String categoryId;
  final bool active;
  final bool isStrict; // If true, matches exact word/phrase. If false, contains.

  CategoryRule({
    required this.id,
    required this.rulePattern,
    required this.categoryId,
    this.active = true,
    this.isStrict = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rulePattern': rulePattern,
      'categoryId': categoryId,
      'active': active,
      'isStrict': isStrict,
    };
  }

  static CategoryRule fromMap(Map<String, dynamic> map) {
    return CategoryRule(
      id: map['id'] ?? '',
      rulePattern: map['rulePattern'] ?? '',
      categoryId: map['categoryId'] ?? '',
      active: map['active'] ?? true,
      isStrict: map['isStrict'] ?? false,
    );
  }

  CategoryRule copyWith({
    String? id,
    String? rulePattern,
    String? categoryId,
    bool? active,
    bool? isStrict,
  }) {
    return CategoryRule(
      id: id ?? this.id,
      rulePattern: rulePattern ?? this.rulePattern,
      categoryId: categoryId ?? this.categoryId,
      active: active ?? this.active,
      isStrict: isStrict ?? this.isStrict,
    );
  }
}
