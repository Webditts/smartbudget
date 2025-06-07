import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class StorageService {
  static const String _budgetKey = 'current_budget';
  static const String _transactionsKey = 'transactions';

  // Budget storage methods
  static Future<void> saveBudget(Budget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetJson = jsonEncode(budget.toJson());
    await prefs.setString(_budgetKey, budgetJson);
  }

  static Future<Budget?> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetJson = prefs.getString(_budgetKey);

    if (budgetJson == null) return null;

    try {
      final budgetMap = jsonDecode(budgetJson) as Map<String, dynamic>;
      return Budget.fromJson(budgetMap);
    } catch (e) {
      print('Error loading budget: $e');
      return null;
    }
  }

  static Future<void> clearBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_budgetKey);
  }

  // Transaction storage methods
  static Future<void> saveTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await loadTransactions(transaction.budgetId);

    transactions.add(transaction);

    final transactionsList = transactions.map((t) => t.toJson()).toList();
    final transactionsJson = jsonEncode(transactionsList);

    await prefs.setString('${_transactionsKey}_${transaction.budgetId}', transactionsJson);
  }

  static Future<List<Transaction>> loadTransactions(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString('${_transactionsKey}_$budgetId');

    if (transactionsJson == null) return [];

    try {
      final transactionsList = jsonDecode(transactionsJson) as List<dynamic>;
      return transactionsList
          .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await loadTransactions(transaction.budgetId);

    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;

      final transactionsList = transactions.map((t) => t.toJson()).toList();
      final transactionsJson = jsonEncode(transactionsList);

      await prefs.setString('${_transactionsKey}_${transaction.budgetId}', transactionsJson);
    }
  }

  static Future<void> deleteTransaction(String transactionId, String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await loadTransactions(budgetId);

    transactions.removeWhere((t) => t.id == transactionId);

    final transactionsList = transactions.map((t) => t.toJson()).toList();
    final transactionsJson = jsonEncode(transactionsList);

    await prefs.setString('${_transactionsKey}_$budgetId', transactionsJson);
  }

  static Future<void> clearTransactions([String? budgetId]) async {
    final prefs = await SharedPreferences.getInstance();

    if (budgetId != null) {
      await prefs.remove('${_transactionsKey}_$budgetId');
    } else {
      // Clear all transaction keys
      final keys = prefs.getKeys();
      final transactionKeys = keys.where((key) => key.startsWith(_transactionsKey));

      for (final key in transactionKeys) {
        await prefs.remove(key);
      }
    }
  }

  // Utility methods
  static Future<bool> hasBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_budgetKey);
  }

  static Future<bool> hasTransactions(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('${_transactionsKey}_$budgetId');
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Backup and restore methods
  static Future<Map<String, dynamic>> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final data = <String, dynamic>{};

    for (final key in keys) {
      if (key.startsWith(_budgetKey) || key.startsWith(_transactionsKey)) {
        data[key] = prefs.getString(key);
      }
    }

    return data;
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    for (final entry in data.entries) {
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value);
      }
    }
  }
}