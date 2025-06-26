import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/budget_controller.dart';
import '../../models/budget_model.dart';
import '../../utils/app_theme.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  _BudgetSetupScreenState createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalAmountController = TextEditingController();

  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  double _needsPercentage = 50.0;
  double _wantsPercentage = 30.0;
  double _emergencyPercentage = 20.0;

  @override
  void dispose() {
    _totalAmountController.dispose();
    super.dispose();
  }

  void _updatePercentages(String category, double value) {
    setState(() {
      switch (category) {
        case 'needs':
          _needsPercentage = value;
          break;
        case 'wants':
          _wantsPercentage = value;
          break;
        case 'emergency':
          _emergencyPercentage = value;
          break;
      }

      // Ensure total doesn't exceed 100%
      final total = _needsPercentage + _wantsPercentage + _emergencyPercentage;
      if (total > 100) {
        final excess = total - 100;
        switch (category) {
          case 'needs':
            _needsPercentage -= excess;
            break;
          case 'wants':
            _wantsPercentage -= excess;
            break;
          case 'emergency':
            _emergencyPercentage -= excess;
            break;
        }
      }
    });
  }

  double get _totalPercentage => _needsPercentage + _wantsPercentage + _emergencyPercentage;
  double get _totalAmount => double.tryParse(_totalAmountController.text) ?? 0.0;

  Future<void> _createBudget() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalPercentage != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget percentages must total 100%'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final budgetController = Provider.of<BudgetController>(context, listen: false);

    await budgetController.createBudget(
      totalAmount: _totalAmount,
      needsPercentage: _needsPercentage,
      wantsPercentage: _wantsPercentage,
      emergencyPercentage: _emergencyPercentage,
      period: _selectedPeriod,
    );

    if (budgetController.error == null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(budgetController.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Budget'),
      ),
      body: Consumer<BudgetController>(
        builder: (context, budgetController, child) {
          if (budgetController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💰 Let\'s Create Your Budget!',
                            style: AppTheme.headingStyle,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Set up your budget to track spending and reach your financial goals.',
                            style: AppTheme.bodyStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Total amount input
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Budget Amount',
                            style: AppTheme.subheadingStyle,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _totalAmountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount (€)',
                              prefixText: '€ ',
                              hintText: '0.00',
                            ),
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
                            onChanged: (value) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Budget period selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget Period',
                            style: AppTheme.subheadingStyle,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<BudgetPeriod>(
                                  title: const Text('Weekly'),
                                  value: BudgetPeriod.weekly,
                                  groupValue: _selectedPeriod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPeriod = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<BudgetPeriod>(
                                  title: const Text('Monthly'),
                                  value: BudgetPeriod.monthly,
                                  groupValue: _selectedPeriod,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPeriod = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Budget allocation
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget Allocation',
                            style: AppTheme.subheadingStyle,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Adjust the percentages for each category:',
                            style: AppTheme.captionStyle,
                          ),
                          const SizedBox(height: 16),

                          // Needs slider
                          _buildCategorySlider(
                            'Needs',
                            '🍽️',
                            'Food, transport, school supplies',
                            _needsPercentage,
                            AppTheme.needsColor,
                                (value) => _updatePercentages('needs', value),
                          ),
                          const SizedBox(height: 16),

                          // Wants slider
                          _buildCategorySlider(
                            'Wants',
                            '🎮',
                            'Entertainment, hobbies, treats',
                            _wantsPercentage,
                            AppTheme.wantsColor,
                                (value) => _updatePercentages('wants', value),
                          ),
                          const SizedBox(height: 16),

                          // Emergency slider
                          _buildCategorySlider(
                            'Emergency',
                            '🚨',
                            'Unexpected urgent expenses',
                            _emergencyPercentage,
                            AppTheme.emergencyColor,
                                (value) => _updatePercentages('emergency', value),
                          ),
                          const SizedBox(height: 16),

                          // Total percentage indicator
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _totalPercentage == 100
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _totalPercentage == 100
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Allocation:'),
                                Text(
                                  '${_totalPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _totalPercentage == 100
                                        ? AppTheme.successColor
                                        : AppTheme.warningColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Budget preview
                  if (_totalAmount > 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget Preview',
                              style: AppTheme.subheadingStyle,
                            ),
                            const SizedBox(height: 12),
                            _buildPreviewRow(
                              'Needs',
                              _totalAmount * (_needsPercentage / 100),
                              AppTheme.needsColor,
                            ),
                            _buildPreviewRow(
                              'Wants',
                              _totalAmount * (_wantsPercentage / 100),
                              AppTheme.wantsColor,
                            ),
                            _buildPreviewRow(
                              'Emergency',
                              _totalAmount * (_emergencyPercentage / 100),
                              AppTheme.emergencyColor,
                            ),
                            const Divider(),
                            _buildPreviewRow(
                              'Total',
                              _totalAmount,
                              AppTheme.primaryColor,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Create budget button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createBudget,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Create Budget',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySlider(
      String title,
      String emoji,
      String description,
      double value,
      Color color,
      ValueChanged<double> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(title, style: AppTheme.bodyStyle),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          description,
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTheme.subheadingStyle : AppTheme.bodyStyle,
          ),
          Text(
            '€ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}