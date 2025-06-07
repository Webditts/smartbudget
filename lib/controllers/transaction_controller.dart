import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';

class TransactionController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add a new transaction
  Future<bool> addTransaction({
    required double amount,
    required TransactionCategory category,
    required String budgetId,
    String? description,
  }) async {
    _setLoading(true);
    try {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        category: category,
        description: description,
        createdAt: DateTime.now(),
        budgetId: budgetId,
      );

      await StorageService.saveTransaction(transaction);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get transactions for a specific budget
  Future<List<Transaction>> getTransactionsForBudget(String budgetId) async {
    try {
      return await StorageService.loadTransactions(budgetId);
    } catch (e) {
      _setError('Failed to load transactions: $e');
      return [];
    }
  }

  // Get recent transactions (last 10)
  Future<List<Transaction>> getRecentTransactions(String budgetId) async {
    try {
      final transactions = await StorageService.loadTransactions(budgetId);
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions.take(10).toList();
    } catch (e) {
      _setError('Failed to load recent transactions: $e');
      return [];
    }
  }

  // Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(
      String budgetId,
      TransactionCategory category,
      ) async {
    try {
      final transactions = await StorageService.loadTransactions(budgetId);
      return transactions.where((t) => t.category == category).toList();
    } catch (e) {
      _setError('Failed to load transactions by category: $e');
      return [];
    }
  }

  // Get daily spending for charts
  Future<Map<DateTime, double>> getDailySpending(String budgetId) async {
    try {
      final transactions = await StorageService.loadTransactions(budgetId);
      final Map<DateTime, double> dailySpending = {};

      for (final transaction in transactions) {
        final date = DateTime(
          transaction.createdAt.year,
          transaction.createdAt.month,
          transaction.createdAt.day,
        );

        dailySpending[date] = (dailySpending[date] ?? 0.0) + transaction.amount;
      }

      return dailySpending;
    } catch (e) {
      _setError('Failed to calculate daily spending: $e');
      return {};
    }
  }

  // Get spending by category for pie chart
  Future<Map<TransactionCategory, double>> getSpendingByCategory(String budgetId) async {
    try {
      final transactions = await StorageService.loadTransactions(budgetId);
      final Map<TransactionCategory, double> categorySpending = {
        TransactionCategory.needs: 0.0,
        TransactionCategory.wants: 0.0,
        TransactionCategory.emergency: 0.0,
      };

      for (final transaction in transactions) {
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0.0) + transaction.amount;
      }

      return categorySpending;
    } catch (e) {
      _setError('Failed to calculate category spending: $e');
      return {};
    }
  }

  // Delete a transaction
  Future<bool> deleteTransaction(String transactionId, String budgetId) async {
    _setLoading(true);
    try {
      await StorageService.deleteTransaction(transactionId, budgetId);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      await StorageService.updateTransaction(transaction);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Validate transaction amount against budget
  bool validateTransaction(
      double amount,
      TransactionCategory category,
      double remainingAmount,
      ) {
    if (amount <= 0) return false;
    return remainingAmount >= amount;
  }

  // Get transaction statistics
  Future<TransactionStats> getTransactionStats(String budgetId) async {
    try {
      final transactions = await StorageService.loadTransactions(budgetId);

      double totalSpent = 0.0;
      double needsSpent = 0.0;
      double wantsSpent = 0.0;
      double emergencySpent = 0.0;

      for (final transaction in transactions) {
        totalSpent += transaction.amount;
        switch (transaction.category) {
          case TransactionCategory.needs:
            needsSpent += transaction.amount;
            break;
          case TransactionCategory.wants:
            wantsSpent += transaction.amount;
            break;
          case TransactionCategory.emergency:
            emergencySpent += transaction.amount;
            break;
        }
      }

      return TransactionStats(
        totalTransactions: transactions.length,
        totalSpent: totalSpent,
        needsSpent: needsSpent,
        wantsSpent: wantsSpent,
        emergencySpent: emergencySpent,
        averageTransaction: transactions.isNotEmpty ? totalSpent / transactions.length : 0.0,
      );
    } catch (e) {
      _setError('Failed to calculate transaction stats: $e');
      return TransactionStats.empty();
    }
  }

  // Helper methods
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

// Transaction statistics model
class TransactionStats {
  final int totalTransactions;
  final double totalSpent;
  final double needsSpent;
  final double wantsSpent;
  final double emergencySpent;
  final double averageTransaction;

  TransactionStats({
    required this.totalTransactions,
    required this.totalSpent,
    required this.needsSpent,
    required this.wantsSpent,
    required this.emergencySpent,
    required this.averageTransaction,
  });

  factory TransactionStats.empty() {
    return TransactionStats(
      totalTransactions: 0,
      totalSpent: 0.0,
      needsSpent: 0.0,
      wantsSpent: 0.0,
      emergencySpent: 0.0,
      averageTransaction: 0.0,
    );
  }
}