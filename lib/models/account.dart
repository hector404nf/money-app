import 'package:flutter/material.dart';

enum AccountType {
  bank,
  cash,
  card,
  savings,
  other,
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.bank:
        return 'Cuenta bancaria';
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.card:
        return 'Tarjeta';
      case AccountType.savings:
        return 'Ahorro';
      case AccountType.other:
        return 'Otro';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.card:
        return Icons.credit_card;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }

  Color get color {
    switch (this) {
      case AccountType.bank:
        return const Color(0xFF00796B); // Teal/Greenish like mockup
      case AccountType.cash:
        return const Color(0xFF2E7D32); // Green
      case AccountType.card:
        return const Color(0xFF1565C0); // Blue
      case AccountType.savings:
        return const Color(0xFFEC407A); // Pink
      case AccountType.other:
        return const Color(0xFF757575); // Grey
    }
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final bool isActive;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'isActive': isActive,
    };
  }

  static Account fromMap(Map<String, dynamic> map) {
    final type = AccountType.values.firstWhere((t) => t.name == map['type']);
    return Account(
      id: map['id'],
      name: map['name'],
      type: type,
      initialBalance: (map['initialBalance'] as num?)?.toDouble() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
