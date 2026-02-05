enum DebtType {
  lending,   // Préstamo dado (Activo / Me deben)
  borrowing, // Préstamo recibido (Pasivo / Debo)
}

class Debt {
  final String id;
  final String name;             // Ej: "Préstamo Auto", "Le presté a Juan"
  final DebtType type;           // Prestar o Pedir prestado
  final double totalAmount;      // Monto original
  final double remainingAmount;  // Saldo pendiente
  final double? interestRate;    // Tasa de interés (opcional)
  final DateTime startDate;      // Fecha de inicio
  final DateTime? endDate;       // Fecha estimada de fin
  final int? totalInstallments;  // Número total de cuotas (si aplica)
  final int paidInstallments;    // Cuotas pagadas
  final String? accountId;       // Cuenta donde se depositó/salió el dinero inicial (opcional)
  final bool isArchived;         // Para ocultar deudas saldadas

  const Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.remainingAmount,
    required this.startDate,
    this.interestRate,
    this.endDate,
    this.totalInstallments,
    this.paidInstallments = 0,
    this.accountId,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'interestRate': interestRate,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'accountId': accountId,
      'isArchived': isArchived,
    };
  }

  static Debt fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      type: DebtType.values.firstWhere((t) => t.name == map['type'], orElse: () => DebtType.borrowing),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      remainingAmount: (map['remainingAmount'] as num).toDouble(),
      interestRate: map['interestRate'] != null ? (map['interestRate'] as num).toDouble() : null,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate']) : null,
      totalInstallments: map['totalInstallments'],
      paidInstallments: map['paidInstallments'] ?? 0,
      accountId: map['accountId'],
      isArchived: map['isArchived'] ?? false,
    );
  }

  Debt copyWith({
    String? id,
    String? name,
    DebtType? type,
    double? totalAmount,
    double? remainingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? endDate,
    int? totalInstallments,
    int? paidInstallments,
    String? accountId,
    bool? isArchived,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      accountId: accountId ?? this.accountId,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
