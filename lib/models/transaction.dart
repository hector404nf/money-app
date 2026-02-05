enum MainType {
  incomes,
  expenses,
}

enum TransactionStatus {
  pagado,
  pendiente,
  programado,
}

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class Transaction {
  final String id;
  final DateTime date;
  final String monthKey; // Formato YYYY-MM
  final MainType mainType;
  final String categoryId;
  final String? subCategory;
  final String accountId;
  final double amount;
  final TransactionStatus status;
  final DateTime? dueDate;
  final String? notes;
  final List<String> tags;
  final String? goalId;
  final bool isRecurring;
  final RecurringFrequency? frequency;
  final DateTime? recursUntil;
  final String? parentRecurringId;
  final String? eventId;
  final double? originalAmount;
  final String? originalCurrency;
  final double? exchangeRate;
  final String? debtId;

  const Transaction({
    required this.id,
    required this.date,
    required this.monthKey,
    required this.mainType,
    required this.categoryId,
    required this.accountId,
    required this.amount,
    required this.status,
    this.subCategory,
    this.dueDate,
    this.notes,
    this.tags = const [],
    this.goalId,
    this.isRecurring = false,
    this.frequency,
    this.recursUntil,
    this.parentRecurringId,
    this.eventId,
    this.originalAmount,
    this.originalCurrency,
    this.exchangeRate,
    this.debtId,
  });

  Transaction copyWith({
    String? id,
    DateTime? date,
    String? monthKey,
    MainType? mainType,
    String? categoryId,
    String? subCategory,
    String? accountId,
    double? amount,
    TransactionStatus? status,
    DateTime? dueDate,
    String? notes,
    List<String>? tags,
    String? goalId,
    bool? isRecurring,
    RecurringFrequency? frequency,
    DateTime? recursUntil,
    String? parentRecurringId,
    String? eventId,
    double? originalAmount,
    String? originalCurrency,
    double? exchangeRate,
    String? debtId,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      monthKey: monthKey ?? this.monthKey,
      mainType: mainType ?? this.mainType,
      categoryId: categoryId ?? this.categoryId,
      subCategory: subCategory ?? this.subCategory,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      goalId: goalId ?? this.goalId,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      recursUntil: recursUntil ?? this.recursUntil,
      parentRecurringId: parentRecurringId ?? this.parentRecurringId,
      eventId: eventId ?? this.eventId,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      debtId: debtId ?? this.debtId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'monthKey': monthKey,
      'mainType': mainType.name,
      'categoryId': categoryId,
      'subCategory': subCategory,
      'accountId': accountId,
      'amount': amount,
      'status': status.name,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'notes': notes,
      'tags': tags,
      'goalId': goalId,
      'isRecurring': isRecurring,
      'frequency': frequency?.name,
      'recursUntil': recursUntil?.millisecondsSinceEpoch,
      'parentRecurringId': parentRecurringId,
      'eventId': eventId,
      'originalAmount': originalAmount,
      'originalCurrency': originalCurrency,
      'exchangeRate': exchangeRate,
      'debtId': debtId,
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    final mainType = MainType.values.firstWhere((m) => m.name == map['mainType']);
    final status = TransactionStatus.values.firstWhere((s) => s.name == map['status']);
    final frequencyName = map['frequency'] as String?;
    final RecurringFrequency? frequency = frequencyName == null
        ? null
        : RecurringFrequency.values.firstWhere(
            (f) => f.name == frequencyName,
            orElse: () => RecurringFrequency.monthly,
          );
    return Transaction(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      monthKey: map['monthKey'],
      mainType: mainType,
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      amount: (map['amount'] as num).toDouble(),
      status: status,
      subCategory: map['subCategory'],
      dueDate: map['dueDate'] == null ? null : DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      notes: map['notes'],
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      goalId: map['goalId'],
      isRecurring: map['isRecurring'] as bool? ?? false,
      frequency: frequency,
      recursUntil: map['recursUntil'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['recursUntil']),
      parentRecurringId: map['parentRecurringId'],
      eventId: map['eventId'],
      originalAmount: map['originalAmount'] != null ? (map['originalAmount'] as num).toDouble() : null,
      originalCurrency: map['originalCurrency'],
      exchangeRate: map['exchangeRate'] != null ? (map['exchangeRate'] as num).toDouble() : null,
      debtId: map['debtId'],
    );
  }
}
