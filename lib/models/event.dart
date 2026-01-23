
class Event {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final String? defaultCurrency;
  final bool isActive;

  const Event({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.defaultCurrency,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'defaultCurrency': defaultCurrency,
      'isActive': isActive,
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate']) : null,
      defaultCurrency: map['defaultCurrency'],
      isActive: map['isActive'] ?? true,
    );
  }

  Event copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? defaultCurrency,
    bool? isActive,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      isActive: isActive ?? this.isActive,
    );
  }
}
