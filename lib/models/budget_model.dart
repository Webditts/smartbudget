class Budget {
  final String id;
  final double totalAmount;
  final double needsAmount;
  final double wantsAmount;
  final double emergencyAmount;
  final BudgetPeriod period;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.totalAmount,
    required this.needsAmount,
    required this.wantsAmount,
    required this.emergencyAmount,
    required this.period,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
  });

  // Calculate remaining amounts
  double get needsRemaining => needsAmount;
  double get wantsRemaining => wantsAmount;
  double get emergencyRemaining => emergencyAmount;
  double get totalRemaining => needsRemaining + wantsRemaining + emergencyRemaining;

  // Budget health indicator
  BudgetHealth get health {
    final spentPercentage = ((totalAmount - totalRemaining) / totalAmount) * 100;
    if (spentPercentage < 50) return BudgetHealth.good;
    if (spentPercentage < 80) return BudgetHealth.warning;
    return BudgetHealth.critical;
  }

  String? get usagePercent => null;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'needsAmount': needsAmount,
      'wantsAmount': wantsAmount,
      'emergencyAmount': emergencyAmount,
      'period': period.toString(),
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  // Create from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      totalAmount: json['totalAmount'].toDouble(),
      needsAmount: json['needsAmount'].toDouble(),
      wantsAmount: json['wantsAmount'].toDouble(),
      emergencyAmount: json['emergencyAmount'].toDouble(),
      period: BudgetPeriod.values.firstWhere(
            (e) => e.toString() == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Budget copyWith({
    String? id,
    double? totalAmount,
    double? needsAmount,
    double? wantsAmount,
    double? emergencyAmount,
    BudgetPeriod? period,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Budget(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      needsAmount: needsAmount ?? this.needsAmount,
      wantsAmount: wantsAmount ?? this.wantsAmount,
      emergencyAmount: emergencyAmount ?? this.emergencyAmount,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

enum BudgetPeriod {
  weekly,
  monthly,
}

enum BudgetHealth {
  good,
  warning,
  critical,
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
    }
  }

  int get days {
    switch (this) {
      case BudgetPeriod.weekly:
        return 7;
      case BudgetPeriod.monthly:
        return 30;
    }
  }
}