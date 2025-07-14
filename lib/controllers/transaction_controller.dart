import 'package:flutter/foundation.dart';
// Avoid this ambiguous import
// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction_model.dart' show Transaction, TransactionCategory;

import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _uid => _auth.currentUser?.uid ?? '';

  /// Add a new transaction to Firestore
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

      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

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

  /// Get transactions for a specific budget
  Future<List<Transaction>> getTransactionsForBudget(String budgetId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('budgetId', isEqualTo: budgetId)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _setError('Failed to load transactions: $e');
      return [];
    }
  }

  /// Get recent (last 10) transactions
  Future<List<Transaction>> getRecentTransactions(String budgetId) async {
    try {
      final transactions = await getTransactionsForBudget(budgetId);
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions.take(10).toList();
    } catch (e) {
      _setError('Failed to load recent transactions: $e');
      return [];
    }
  }

  /// Get transactions by category
  Future<List<Transaction>> getTransactionsByCategory(
      String budgetId, TransactionCategory category) async {
    try {
      final transactions = await getTransactionsForBudget(budgetId);
      return transactions.where((t) => t.category == category).toList();
    } catch (e) {
      _setError('Failed to load by category: $e');
      return [];
    }
  }

  /// Daily spending map for charts
  Future<Map<DateTime, double>> getDailySpending(String budgetId) async {
    try {
      final transactions = await getTransactionsForBudget(budgetId);
      final Map<DateTime, double> spending = {};

      for (final t in transactions) {
        final date = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
        spending[date] = (spending[date] ?? 0) + t.amount;
      }

      return spending;
    } catch (e) {
      _setError('Failed to compute daily spending: $e');
      return {};
    }
  }

  /// Spending per category for pie charts
  Future<Map<TransactionCategory, double>> getSpendingByCategory(String budgetId) async {
    try {
      final transactions = await getTransactionsForBudget(budgetId);
      final Map<TransactionCategory, double> totals = {
        TransactionCategory.needs: 0.0,
        TransactionCategory.wants: 0.0,
        TransactionCategory.emergency: 0.0,
      };

      for (final t in transactions) {
        totals[t.category] = (totals[t.category] ?? 0.0) + t.amount;
      }

      return totals;
    } catch (e) {
      _setError('Failed to calculate spending by category: $e');
      return {};
    }
  }

  /// Delete a transaction
  Future<bool> deleteTransaction(String transactionId) async {
    _setLoading(true);
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
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

  /// Update a transaction
  Future<bool> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toJson());

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

  /// Validates if the transaction can be made
  bool validateTransaction(double amount, double remaining) {
    return amount > 0 && amount <= remaining;
  }

  /// Get transaction stats
  Future<TransactionStats> getTransactionStats(String budgetId) async {
    try {
      final transactions = await getTransactionsForBudget(budgetId);
      double total = 0, needs = 0, wants = 0, emergency = 0;

      for (final t in transactions) {
        total += t.amount;
        switch (t.category) {
          case TransactionCategory.needs:
            needs += t.amount;
            break;
          case TransactionCategory.wants:
            wants += t.amount;
            break;
          case TransactionCategory.emergency:
            emergency += t.amount;
            break;
        }
      }

      return TransactionStats(
        totalTransactions: transactions.length,
        totalSpent: total,
        needsSpent: needs,
        wantsSpent: wants,
        emergencySpent: emergency,
        averageTransaction: transactions.isNotEmpty ? total / transactions.length : 0,
      );
    } catch (e) {
      _setError('Failed to generate stats: $e');
      return TransactionStats.empty();
    }
  }

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

// lib/models/transaction_stats.dart

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

