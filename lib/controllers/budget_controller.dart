import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart' as model;
import '../views/auth/firebase_user.dart';

class BudgetController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Budget? _currentBudget;
  List<model.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  Budget? get currentBudget => _currentBudget;
  List<model.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get needsSpent => _sumCategory(model.TransactionCategory.needs);
  double get wantsSpent => _sumCategory(model.TransactionCategory.wants);
  double get emergencySpent => _sumCategory(model.TransactionCategory.emergency);
  double get totalSpent => needsSpent + wantsSpent + emergencySpent;

  double get needsRemaining => _remaining(model.TransactionCategory.needs);
  double get wantsRemaining => _remaining(model.TransactionCategory.wants);
  double get emergencyRemaining => _remaining(model.TransactionCategory.emergency);
  double get totalRemaining => needsRemaining + wantsRemaining + emergencyRemaining;

  BudgetHealth get budgetHealth {
    if (_currentBudget == null) return BudgetHealth.good;
    final spentPercentage = (totalSpent / _currentBudget!.totalAmount) * 100;
    if (spentPercentage < 50) return BudgetHealth.good;
    if (spentPercentage < 80) return BudgetHealth.warning;
    return BudgetHealth.critical;
  }

  Future<void> initialize({String? userId}) async {
    _setLoading(true);
    try {
      await _loadBudget(userId: userId);
      if (_currentBudget != null) {
        await _loadTransactions();
      }
    } catch (e) {
      _setError('Failed to load data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadBudget({String? userId}) async {
    final uid = userId ?? FirebaseUserHelper.uid;
    if (uid == null) {
      _setError('No user ID provided');
      return;
    }

    final snapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final budget = Budget.fromJson(snapshot.docs.first.data());
      if (budget.endDate.isAfter(DateTime.now())) {
        _currentBudget = budget;
      } else {
        _currentBudget = null;
      }
    } else {
      _currentBudget = null;
    }
  }

  Future<void> _loadTransactions() async {
    if (_currentBudget == null) return;

    final snapshot = await _firestore
        .collection('transactions')
        .where('budgetId', isEqualTo: _currentBudget!.id)
        .get();

    _transactions = snapshot.docs
        .map((doc) => model.Transaction.fromJson(doc.data()))
        .toList();
  }

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
      final uid = FirebaseUserHelper.uid;
      if (uid == null) {
        _setError('No logged-in user found');
        _setLoading(false);
        return;
      }

      final budgetRef = _firestore.collection('budgets').doc();
      final budget = Budget(
        id: budgetRef.id,
        userId: uid,
        totalAmount: totalAmount,
        needsAmount: totalAmount * (needsPercentage / 100),
        wantsAmount: totalAmount * (wantsPercentage / 100),
        emergencyAmount: totalAmount * (emergencyPercentage / 100),
        period: period,
        createdAt: now,
        startDate: now,
        endDate: endDate,
      );

      await budgetRef.set(budget.toJson());
      _currentBudget = budget;
      _transactions.clear();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to create budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Future<void> _loadBudget() async {
  //   final uid = FirebaseUserHelper.uid;
  //   if (uid == null) {
  //     _setError('No logged-in user found');
  //     return;
  //   }
  //
  //   final snapshot = await _firestore
  //       .collection('budgets')
  //       .where('userId', isEqualTo: uid)
  //       .orderBy('createdAt', descending: true)
  //       .limit(1)
  //       .get();
  //
  //   if (snapshot.docs.isNotEmpty) {
  //     final budget = Budget.fromJson(snapshot.docs.first.data());
  //     if (budget.endDate.isAfter(DateTime.now())) {
  //       _currentBudget = budget;
  //     } else {
  //       _currentBudget = null;
  //     }
  //   } else {
  //     _currentBudget = null;
  //   }
  // }

  // Future<void> _loadTransactions() async {
  //   if (_currentBudget == null) return;
  //
  //   final snapshot = await _firestore
  //       .collection('transactions')
  //       .where('budgetId', isEqualTo: _currentBudget!.id)
  //       .get();
  //
  //   _transactions = snapshot.docs
  //       .map((doc) => model.Transaction.fromJson(doc.data()))
  //       .toList();
  // }

  Future<void> addTransaction(model.Transaction transaction) async {
    if (_currentBudget == null) {
      _setError('No active budget found');
      return;
    }

    final correctedTransaction = transaction.copyWith(budgetId: _currentBudget!.id);

    await _firestore
        .collection('transactions')
        .doc(correctedTransaction.id)
        .set(correctedTransaction.toJson());

    _transactions.add(correctedTransaction);
    notifyListeners();
  }

  bool canSpend(model.TransactionCategory category, double amount) {
    return getRemainingAmount(category) >= amount;
  }

  double getRemainingAmount(model.TransactionCategory category) {
    switch (category) {
      case model.TransactionCategory.needs:
        return needsRemaining;
      case model.TransactionCategory.wants:
        return wantsRemaining;
      case model.TransactionCategory.emergency:
        return emergencyRemaining;
    }
  }

  Future<void> clearBudget() async {
    if (_currentBudget != null) {
      final budgetId = _currentBudget!.id;
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .where('budgetId', isEqualTo: budgetId)
          .get();

      for (final doc in transactionsSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('budgets').doc(budgetId).delete();
    }

    _currentBudget = null;
    _transactions.clear();
    _clearError();
    notifyListeners();
  }

  double _sumCategory(model.TransactionCategory category) {
    return _transactions
        .where((t) => t.category == category)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _remaining(model.TransactionCategory category) {
    switch (category) {
      case model.TransactionCategory.needs:
        return (_currentBudget?.needsAmount ?? 0.0) - needsSpent;
      case model.TransactionCategory.wants:
        return (_currentBudget?.wantsAmount ?? 0.0) - wantsSpent;
      case model.TransactionCategory.emergency:
        return (_currentBudget?.emergencyAmount ?? 0.0) - emergencySpent;
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
