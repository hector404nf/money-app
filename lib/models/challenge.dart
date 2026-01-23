class Challenge {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final String type; // 'no_expense', 'savings_goal'
  final String? targetCategoryId; // For 'no_expense' in specific category
  final double? targetAmount; // For 'savings_goal'

  // State (Mutable)
  bool isActive;
  DateTime? startDate;
  bool isCompleted;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.type,
    this.targetCategoryId,
    this.targetAmount,
    this.isActive = false,
    this.startDate,
    this.isCompleted = false,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? durationDays,
    String? type,
    String? targetCategoryId,
    double? targetAmount,
    bool? isActive,
    DateTime? startDate,
    bool? isCompleted,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      type: type ?? this.type,
      targetCategoryId: targetCategoryId ?? this.targetCategoryId,
      targetAmount: targetAmount ?? this.targetAmount,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationDays': durationDays,
      'type': type,
      'targetCategoryId': targetCategoryId,
      'targetAmount': targetAmount,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      durationDays: map['durationDays'],
      type: map['type'],
      targetCategoryId: map['targetCategoryId'],
      targetAmount: map['targetAmount']?.toDouble(),
      isActive: map['isActive'] ?? false,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
