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

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.toString(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'budgetId': budgetId,
    };
  }

  // Create from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      category: TransactionCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
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

enum TransactionCategory {
  needs,
  wants,
  emergency,
}

extension TransactionCategoryExtension on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.needs:
        return 'Needs';
      case TransactionCategory.wants:
        return 'Wants';
      case TransactionCategory.emergency:
        return 'Emergency';
    }
  }

  String get description {
    switch (this) {
      case TransactionCategory.needs:
        return 'Essential expenses like food, transport, school supplies';
      case TransactionCategory.wants:
        return 'Entertainment, hobbies, non-essential purchases';
      case TransactionCategory.emergency:
        return 'Unexpected urgent expenses';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.needs:
        return '🍽️';
      case TransactionCategory.wants:
        return '🎮';
      case TransactionCategory.emergency:
        return '🚨';
    }
  }
}
