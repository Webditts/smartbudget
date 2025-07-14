import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/budget_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/app_theme.dart';
import 'budget_analytics_screen.dart';
import 'saving_tips_screen.dart';
import 'budget_goals_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  _StudentDashboardScreenState createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetController = Provider.of<BudgetController>(context, listen: false);
      budgetController.initialize();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Budget'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_budget':
                  _showNewBudgetDialog();
                  break;
                case 'settings':
                  _showThemeSettingsDialog(context); // ✅ Now implemented
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'new_budget',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('New Budget'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BudgetController>(
        builder: (context, budgetController, child) {
          if (budgetController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetController.currentBudget == null) {
            return _buildNoBudgetState();
          }

          return _buildDashboardContent(budgetController);
        },
      ),
      floatingActionButton: Consumer<BudgetController>(
        builder: (context, budgetController, child) {
          if (budgetController.currentBudget == null) return Container();

          return FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/transaction-entry'),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  /// ✅ Theme Settings Dialog
  void _showThemeSettingsDialog(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context, listen: false);
    final currentMode = themeController.themeMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (mode) {
                  themeController.setTheme(mode!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (mode) {
                  themeController.setTheme(mode!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (mode) {
                  themeController.setTheme(mode!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoBudgetState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Smart Budget!',
              style: AppTheme.headingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Let\'s create your first budget to start tracking your spending and reaching your financial goals.',
              style: AppTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/budget-setup'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('Create Your Budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BudgetController budgetController) {
    final budget = budgetController.currentBudget!;
    final daysRemaining = budget.endDate.difference(DateTime.now()).inDays;

    return RefreshIndicator(
      onRefresh: () => budgetController.initialize(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget overview card
            _buildBudgetOverviewCard(budgetController, daysRemaining),
            const SizedBox(height: 16),

            // Category breakdown
            _buildCategoryBreakdown(budgetController),
            const SizedBox(height: 16),

            // Recent transactions
            _buildRecentTransactions(budgetController),
            const SizedBox(height: 16),

            // Quick actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverviewCard(BudgetController budgetController, int daysRemaining) {
    final budget = budgetController.currentBudget!;
    final healthColor = AppTheme.getBudgetHealthColor(
        double.tryParse(budget.usagePercent ?? '0') ?? 0.0
    );


    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${budget.period.displayName} Budget',
                      style: AppTheme.subheadingStyle,
                    ),
                    Text(
                      '$daysRemaining days remaining',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: healthColor),
                  ),
                  child: Text(
                    budgetController.budgetHealth.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: healthColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Spending progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spent', style: AppTheme.captionStyle),
                    Text(
                      '€ ${budgetController.totalSpent.toStringAsFixed(2)}',
                      style: AppTheme.amountStyle.copyWith(color: AppTheme.errorColor),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Remaining', style: AppTheme.captionStyle),
                    Text(
                      '€ ${budgetController.totalRemaining.toStringAsFixed(2)}',
                      style: AppTheme.amountStyle.copyWith(color: AppTheme.successColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: budgetController.totalSpent / budget.totalAmount,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Budget: € ${budget.totalAmount.toStringAsFixed(2)}',
              style: AppTheme.captionStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(BudgetController budgetController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Breakdown',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),
        _buildCategoryCard(
          'Needs',
          '🍽️',
          budgetController.currentBudget!.needsAmount,
          budgetController.needsSpent,
          budgetController.needsRemaining,
          AppTheme.needsColor,
        ),
        const SizedBox(height: 8),
        _buildCategoryCard(
          'Wants',
          '🎮',
          budgetController.currentBudget!.wantsAmount,
          budgetController.wantsSpent,
          budgetController.wantsRemaining,
          AppTheme.wantsColor,
        ),
        const SizedBox(height: 8),
        _buildCategoryCard(
          'Emergency',
          '🚨',
          budgetController.currentBudget!.emergencyAmount,
          budgetController.emergencySpent,
          budgetController.emergencyRemaining,
          AppTheme.emergencyColor,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      String title,
      String emoji,
      double budgeted,
      double spent,
      double remaining,
      Color color,
      ) {
    final progress = budgeted > 0 ? spent / budgeted : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.bodyStyle),
                      Text(
                        '€${remaining.toStringAsFixed(2)} remaining',
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${spent.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'of €${budgeted.toStringAsFixed(2)}',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1.0 ? AppTheme.errorColor : color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentTransactions(BudgetController budgetController) {
    final recentTransactions = budgetController.transactions
        .where((t) => t.budgetId == budgetController.currentBudget!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final displayTransactions = recentTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: AppTheme.subheadingStyle,
            ),
            if (recentTransactions.length > 5)
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/transactions'),
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayTransactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start adding your expenses to track your spending',
                    style: AppTheme.captionStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...displayTransactions.map((transaction) => _buildTransactionTile(transaction)),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final categoryColor = _getCategoryColor(transaction.category);
    final categoryIcon = _getCategoryIcon(transaction.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryColor.withOpacity(0.1),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description ?? 'No description',
          style: AppTheme.bodyStyle,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.category.toString().split('.').last,
              style: AppTheme.captionStyle,
            ),
            Text(
              DateFormat('MMM dd, yyyy - HH:mm').format(transaction.createdAt),
              style: AppTheme.captionStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          '-€ ${transaction.amount.toStringAsFixed(2)}',
          style: AppTheme.amountStyle.copyWith(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // TODO: Navigate to transaction details
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),
        Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Add Expense',
                  Icons.add_shopping_cart,
                  AppTheme.errorColor,
                      () => Navigator.pushNamed(context, '/transaction-entry'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'View Reports',
                  Icons.bar_chart,
                  AppTheme.primaryColor,
                      () {
                    final budgetController = Provider.of<BudgetController>(context, listen: false);

                    // Check if there's a current budget with user info
                    if (budgetController.currentBudget != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetAnalyticsScreen(
                            studentUserId: budgetController.currentBudget!.userId, // Assuming userId exists in budget model
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No budget data available')),
                      );
                    }
                  },
                ),
              ),
            ]
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Budget Goals',
                Icons.flag,
                AppTheme.successColor,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BudgetGoalsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Savings Tips',
                Icons.lightbulb,
                AppTheme.wantsColor,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavingTipsScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildQuickActionCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Budget'),
        content: const Text(
          'Creating a new budget will replace your current budget. All existing data will be saved but no longer active.\n\nWould you like to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/budget-setup');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.needs:
        return AppTheme.needsColor;
      case TransactionCategory.wants:
        return AppTheme.wantsColor;
      case TransactionCategory.emergency:
        return AppTheme.emergencyColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.needs:
        return Icons.restaurant;
      case TransactionCategory.wants:
        return Icons.shopping_bag;
      case TransactionCategory.emergency:
        return Icons.warning;
      default:
        return Icons.attach_money;
    }
  }
}