enum TransactionCategory {
  needs,
  wants,
  emergency,
}

class Transaction {
  final String id;
  final double amount;
  final TransactionCategory category;
  final String? description;
  final DateTime createdAt;
  final String budgetId;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.createdAt,
    required this.budgetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name, // store enum as string (e.g. "needs")
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'budgetId': budgetId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: TransactionCategory.values.firstWhere(
            (e) => e.name == json['category'],
        orElse: () => TransactionCategory.needs,
      ),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      budgetId: json['budgetId'],
    );
  }

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionCategory? category,
    String? description,
    DateTime? createdAt,
    String? budgetId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      budgetId: budgetId ?? this.budgetId,
    );
  }
}
