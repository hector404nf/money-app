class EmailTransactionCandidate {
  final String messageId;
  final DateTime date;
  final double amount;
  final String currency;
  final String description;
  final String bankName;

  EmailTransactionCandidate({
    required this.messageId,
    required this.date,
    required this.amount,
    required this.currency,
    required this.description,
    required this.bankName,
  });
}

