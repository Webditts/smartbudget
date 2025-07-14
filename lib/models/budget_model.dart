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

class Budget {
  final String id;
  final String userId; // ✅ New field for Firebase filtering
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
    required this.userId,
    required this.totalAmount,
    required this.needsAmount,
    required this.wantsAmount,
    required this.emergencyAmount,
    required this.period,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
  });

  // Remaining calculated amounts
  double get needsRemaining => needsAmount;
  double get wantsRemaining => wantsAmount;
  double get emergencyRemaining => emergencyAmount;
  double get totalRemaining => needsRemaining + wantsRemaining + emergencyRemaining;

  // Usage percentage
  String get usagePercent {
    final used = totalAmount - totalRemaining;
    final percent = (used / totalAmount * 100).clamp(0, 100);
    return '${percent.toStringAsFixed(1)}%';
  }

  // Budget health indicator
  BudgetHealth get health {
    final spentPercentage = ((totalAmount - totalRemaining) / totalAmount) * 100;
    if (spentPercentage < 50) return BudgetHealth.good;
    if (spentPercentage < 80) return BudgetHealth.warning;
    return BudgetHealth.critical;
  }

  // Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
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

  // Load from Firestore JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['userId'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      needsAmount: (json['needsAmount'] as num).toDouble(),
      wantsAmount: (json['wantsAmount'] as num).toDouble(),
      emergencyAmount: (json['emergencyAmount'] as num).toDouble(),
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
    String? userId,
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
      userId: userId ?? this.userId,
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
