enum MainType {
  incomes,
  expenses,
}

enum TransactionStatus {
  pagado,
  pendiente,
  programado,
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
  });

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
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    final mainType = MainType.values.firstWhere((m) => m.name == map['mainType']);
    final status = TransactionStatus.values.firstWhere((s) => s.name == map['status']);
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
    );
  }
}
