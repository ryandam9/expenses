class Expense {
  final String date;
  final String description;
  final double debit;
  final double credit;
  final String source;
  final String category;

  Expense({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.source,
    required this.category,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      date: map['date'] as String? ?? '',
      description: map['description'] as String? ?? '',
      debit: double.tryParse(map['debit']?.toString() ?? '0') ?? 0,
      credit: double.tryParse(map['credit']?.toString() ?? '0') ?? 0,
      source: map['source'] as String? ?? '',
      category: map['category'] as String? ?? '',
    );
  }

  double get amount => debit > 0 ? -debit : credit;
}
