import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/budget_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';

class TransactionEntryScreen extends StatefulWidget {
  const TransactionEntryScreen({super.key});

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionCategory _selectedCategory = TransactionCategory.needs;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<TransactionController, BudgetController>(
        builder: (context, transactionController, budgetController, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildBudgetSummaryCard(budgetController),
                  const SizedBox(height: 24),
                  _buildAmountInput(),
                  const SizedBox(height: 20),
                  _buildCategorySelection(budgetController),
                  const SizedBox(height: 20),
                  _buildDescriptionInput(),
                  const SizedBox(height: 32),
                  _buildSaveButton(transactionController, budgetController),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetSummaryCard(BudgetController controller) {
    if (controller.currentBudget == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Summary',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Total Remaining',
                  '€ ${controller.totalRemaining.toStringAsFixed(2)}',
                  AppTheme.successColor,
                ),
                _buildSummaryItem(
                  'Total Spent',
                  '€ ${controller.totalSpent.toStringAsFixed(2)}',
                  AppTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.captionStyle),
        Text(
          value,
          style: AppTheme.amountStyle.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '€ ',
            prefixStyle: AppTheme.bodyStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: AppTheme.amountStyle,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelection(BudgetController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),
        ...TransactionCategory.values.map((category) {
          return _buildCategoryOption(category, controller);
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryOption(TransactionCategory category, BudgetController controller) {
    final isSelected = _selectedCategory == category;
    final categoryData = _getCategoryData(category);
    final remaining = _getCategoryRemaining(category, controller);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? categoryData['color']
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedCategory = category),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  categoryData['icon'],
                  color: categoryData['color'],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryData['title'],
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    Text(
                      '€ ${remaining.toStringAsFixed(2)} remaining',
                      style: AppTheme.captionStyle.copyWith(
                        color: remaining > 0 ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: categoryData['color'],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'What did you spend on?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(TransactionController tController, BudgetController bController) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _saveTransaction(tController, bController),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Save Expense',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction(
      TransactionController tController,
      BudgetController bController,
      ) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();
    final budget = bController.currentBudget;

    if (budget == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active budget found')),
        );
      }
      return;
    }

    final remaining = _getCategoryRemaining(_selectedCategory, bController);
    if (amount > remaining) {
      final confirmed = await _showOverspendConfirmation(amount, remaining);
      if (!confirmed) return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await tController.addTransaction(
        amount: amount,
        category: _selectedCategory,
        budgetId: budget.id,
        description: description.isNotEmpty ? description : null,
      );

      if (success && mounted) {
        await bController.initialize();
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showOverspendConfirmation(double amount, double remaining) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Overspend'),
        content: Text(
          'You\'re about to spend € ${amount.toStringAsFixed(2)} '
              'which exceeds your remaining budget of € ${remaining.toStringAsFixed(2)}.\n\n'
              'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _descriptionController.clear();
    setState(() => _selectedCategory = TransactionCategory.needs);
  }

  Map<String, dynamic> _getCategoryData(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.needs:
        return {
          'title': 'Needs',
          'color': AppTheme.primaryColor,
          'icon': Icons.shopping_cart,
        };
      case TransactionCategory.wants:
        return {
          'title': 'Wants',
          'color': AppTheme.secondaryColor,
          'icon': Icons.local_mall,
        };
      case TransactionCategory.emergency:
        return {
          'title': 'Emergency',
          'color': AppTheme.errorColor,
          'icon': Icons.emergency,
        };
    }
  }

  double _getCategoryRemaining(TransactionCategory category, BudgetController controller) {
    final budget = controller.currentBudget;
    if (budget == null) return 0.0;

    switch (category) {
      case TransactionCategory.needs:
        return budget.needsRemaining;
      case TransactionCategory.wants:
        return budget.wantsRemaining;
      case TransactionCategory.emergency:
        return budget.emergencyRemaining;
    }
  }
}