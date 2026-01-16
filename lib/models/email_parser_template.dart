class EmailParserTemplate {
  final String id;
  final String name;
  final String senderFilter; // Filter by sender (optional)
  final String subjectFilter; // Filter by subject (optional)
  
  // Extraction logic: "Between" strategy
  final String amountPrefix; // Text immediately before the amount
  final String amountSuffix; // Text immediately after the amount (optional)
  
  final bool isExpense; // If matched, is it an expense?

  EmailParserTemplate({
    required this.id,
    required this.name,
    this.senderFilter = '',
    this.subjectFilter = '',
    required this.amountPrefix,
    this.amountSuffix = '',
    this.isExpense = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'senderFilter': senderFilter,
      'subjectFilter': subjectFilter,
      'amountPrefix': amountPrefix,
      'amountSuffix': amountSuffix,
      'isExpense': isExpense,
    };
  }

  factory EmailParserTemplate.fromMap(Map<String, dynamic> map) {
    return EmailParserTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      senderFilter: map['senderFilter'] ?? '',
      subjectFilter: map['subjectFilter'] ?? '',
      amountPrefix: map['amountPrefix'] ?? '',
      amountSuffix: map['amountSuffix'] ?? '',
      isExpense: map['isExpense'] ?? true,
    );
  }

  // Helper to test if this template applies to a given email
  bool matches(String sender, String subject, String body) {
    if (senderFilter.isNotEmpty && !sender.toLowerCase().contains(senderFilter.toLowerCase())) {
      return false;
    }
    // Check subject OR body for the filter if specified
    if (subjectFilter.isNotEmpty) {
      bool subjectMatch = subject.toLowerCase().contains(subjectFilter.toLowerCase());
      bool bodyMatch = body.toLowerCase().contains(subjectFilter.toLowerCase());
      if (!subjectMatch && !bodyMatch) return false;
    }
    return true;
  }

  // Helper to extract amount
  double? extractAmount(String text) {
    if (amountPrefix.isEmpty) return null;

    final lowerText = text.toLowerCase();
    final lowerPrefix = amountPrefix.toLowerCase();
    
    final startIndex = lowerText.indexOf(lowerPrefix);
    if (startIndex == -1) return null;

    final valueStartIndex = startIndex + lowerPrefix.length;
    String remainder = text.substring(valueStartIndex).trim();

    if (amountSuffix.isNotEmpty) {
      final lowerSuffix = amountSuffix.toLowerCase();
      final endIndex = remainder.toLowerCase().indexOf(lowerSuffix);
      if (endIndex != -1) {
        remainder = remainder.substring(0, endIndex).trim();
      }
    } else {
      // If no suffix, try to take the first number sequence
      // Simple logic: take until first space that is followed by non-digit/non-punctuation
      // or just take the first word
      final parts = remainder.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) remainder = parts[0];
    }

    // Clean up currency symbols and format
    // Remove all non-numeric chars except . , and -
    String clean = remainder.replaceAll(RegExp(r'[^\d.,-]'), '');
    
    // Normalize decimal separator
    // If it has comma and dot, assume dot is thousands if it comes first?
    // Let's use the same logic as EmailImportService if possible, or a simplified one.
    // "1.500.000" -> 1500000
    // "1,500,000" -> 1500000
    // "1500,00" -> 1500.00
    
    // Heuristic: remove . if there are multiple, or if there is a comma later.
    clean = clean.replaceAll('.', '').replaceAll(',', '.');
    
    return double.tryParse(clean);
  }
}
