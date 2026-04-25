class Expense {
  final int? id;
  final int categoryId;
  final double amount;
  final String description;
  final DateTime date;

  const Expense({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        categoryId: map['categoryId'] as int,
        amount: (map['amount'] as num).toDouble(),
        description: map['description'] as String,
        date: DateTime.parse(map['date'] as String),
      );

  Expense copyWith({
    int? id,
    int? categoryId,
    double? amount,
    String? description,
    DateTime? date,
  }) =>
      Expense(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        date: date ?? this.date,
      );
}
