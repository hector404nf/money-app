enum CategoryKind {
  income,
  expense,
  transfer,
  debt,
}

class Category {
  final String id;
  final String name;
  final String? iconName;
  final CategoryKind kind;
  final bool isTransferLike;
  final bool isMoneyLike;
  final bool isDebtLike;
  final double? monthlyBudget;

  Category({
    required this.id,
    required this.name,
    required this.kind,
    this.iconName,
    this.isTransferLike = false,
    this.isMoneyLike = false,
    this.isDebtLike = false,
    this.monthlyBudget,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'kind': kind.name,
      'isTransferLike': isTransferLike,
      'isMoneyLike': isMoneyLike,
      'isDebtLike': isDebtLike,
      'monthlyBudget': monthlyBudget,
    };
  }

  static Category fromMap(Map<String, dynamic> map) {
    final kind = CategoryKind.values.firstWhere((k) => k.name == map['kind']);
    return Category(
      id: map['id'],
      name: map['name'],
      iconName: map['iconName'],
      kind: kind,
      isTransferLike: map['isTransferLike'] as bool? ?? false,
      isMoneyLike: map['isMoneyLike'] as bool? ?? false,
      isDebtLike: map['isDebtLike'] as bool? ?? false,
      monthlyBudget: map['monthlyBudget'] as double?,
    );
  }
}
