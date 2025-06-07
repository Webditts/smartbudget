import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';

class BudgetController extends ChangeNotifier {
  Budget? _currentBudget;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Dummy transaction loading
  Future<void> loadData() async {
    _transactions = await fetchTransactions(); // Example
    notifyListeners();
  }

  Future<List<Transaction>> fetchTransactions() async {
    return [
      Transaction(
        id: '1',
        amount: 20.0,
        category: TransactionCategory.needs,
        createdAt: DateTime.now(),
        budgetId: 'budget1',
      )

      // Add more dummy transactions as needed
    ];
  }

  Budget? get currentBudget => _currentBudget;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculate spent amounts by category
  double get needsSpent => _transactions
      .where((t) => t.category == TransactionCategory.needs)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get wantsSpent => _transactions
      .where((t) => t.category == TransactionCategory.wants)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get emergencySpent => _transactions
      .where((t) => t.category == TransactionCategory.emergency)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalSpent => needsSpent + wantsSpent + emergencySpent;

  // Calculate remaining amounts
  double get needsRemaining =>
      _currentBudget != null ? _currentBudget!.needsAmount - needsSpent : 0.0;

  double get wantsRemaining =>
      _currentBudget != null ? _currentBudget!.wantsAmount - wantsSpent : 0.0;

  double get emergencyRemaining =>
      _currentBudget != null ? _currentBudget!.emergencyAmount - emergencySpent : 0.0;

  double get totalRemaining => needsRemaining + wantsRemaining + emergencyRemaining;

  // Budget health indicator
  BudgetHealth get budgetHealth {
    if (_currentBudget == null) return BudgetHealth.good;

    final spentPercentage = (totalSpent / _currentBudget!.totalAmount) * 100;
    if (spentPercentage < 50) return BudgetHealth.good;
    if (spentPercentage < 80) return BudgetHealth.warning;
    return BudgetHealth.critical;
  }

  // Initialize controller
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadBudget();
      await _loadTransactions();
    } catch (e) {
      _setError('Failed to load data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new budget
  Future<void> createBudget({
    required double totalAmount,
    required double needsPercentage,
    required double wantsPercentage,
    required double emergencyPercentage,
    required BudgetPeriod period,
  }) async {
    _setLoading(true);
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: period.days));

      final budget = Budget(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        totalAmount: totalAmount,
        needsAmount: totalAmount * (needsPercentage / 100),
        wantsAmount: totalAmount * (wantsPercentage / 100),
        emergencyAmount: totalAmount * (emergencyPercentage / 100),
        period: period,
        createdAt: now,
        startDate: now,
        endDate: endDate,
      );

      await StorageService.saveBudget(budget);
      _currentBudget = budget;
      _transactions.clear(); // Clear old transactions
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to create budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load budget from storage
  Future<void> _loadBudget() async {
    final budget = await StorageService.loadBudget();
    if (budget != null) {
      if (budget.endDate.isAfter(DateTime.now())) {
        _currentBudget = budget;
      } else {
        await StorageService.clearBudget();
        _currentBudget = null;
      }
    }
  }

  // Load transactions from storage
  Future<void> _loadTransactions() async {
    if (_currentBudget != null) {
      _transactions = await StorageService.loadTransactions(_currentBudget!.id);
    }
  }

  // Add a transaction
  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  // Can spend check
  bool canSpend(TransactionCategory category, double amount) {
    switch (category) {
      case TransactionCategory.needs:
        return needsRemaining >= amount;
      case TransactionCategory.wants:
        return wantsRemaining >= amount;
      case TransactionCategory.emergency:
        return emergencyRemaining >= amount;
    }
  }

  // Get remaining for a category
  double getRemainingAmount(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.needs:
        return needsRemaining;
      case TransactionCategory.wants:
        return wantsRemaining;
      case TransactionCategory.emergency:
        return emergencyRemaining;
    }
  }

  // Clear budget
  Future<void> clearBudget() async {
    await StorageService.clearBudget();
    await StorageService.clearTransactions();
    _currentBudget = null;
    _transactions.clear();
    _clearError();
    notifyListeners();
  }

  // Helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
