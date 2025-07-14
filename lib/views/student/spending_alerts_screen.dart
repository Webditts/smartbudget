import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/models/transaction_model.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart' ;
import '../../controllers/auth_controller.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class AlertItem {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final AlertSeverity severity;
  final DateTime createdAt;
  final String studentEmail;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.createdAt,
    required this.studentEmail,
    this.isRead = false,
    this.metadata,
  });
}

enum AlertType {
  budgetExceeded,
  spendingPattern,
  unusualActivity,
  categoryLimit,
  dailyLimit,
  weeklyLimit,
  monthlyLimit,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class SpendingAlertsScreen extends StatefulWidget {
  const SpendingAlertsScreen({super.key});

  @override
  _SpendingAlertsScreenState createState() => _SpendingAlertsScreenState();
}

class _SpendingAlertsScreenState extends State<SpendingAlertsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<AlertItem> alerts = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Critical', 'Warning', 'Info', 'Unread'];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final parentUser = authController.currentUser;

      if (parentUser?.studentEmail != null) {
        // Find the student user
        final studentQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: parentUser!.studentEmail)
            .where('role', isEqualTo: 'UserRole.student')
            .get();

        if (studentQuery.docs.isNotEmpty) {
          final studentDoc = studentQuery.docs.first;
          final studentUser = AppUser.fromJson(studentDoc.data());
          await _generateAlertsForStudent(studentUser);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading alerts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateAlertsForStudent(AppUser student) async {
    List<AlertItem> generatedAlerts = [];

    try {
      // Get student's current budget
      final budgetQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: student.id)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (budgetQuery.docs.isNotEmpty) {
        final budget = Budget.fromJson(budgetQuery.docs.first.data());

        // Get transactions for this budget
        final transactionQuery = await _firestore
            .collection('transactions')
            .where('budgetId', isEqualTo: budget.id)
            .orderBy('createdAt', descending: true)
            .get();

        final transactions = transactionQuery.docs
            .map((doc) => model.Transaction.fromJson(doc.data()))
            .toList();

        // Generate different types of alerts
        generatedAlerts.addAll(_generateBudgetAlerts(student, budget, transactions));
        generatedAlerts.addAll(_generateSpendingPatternAlerts(student, transactions));
        generatedAlerts.addAll(_generateUnusualActivityAlerts(student, transactions));
        generatedAlerts.addAll(_generateCategoryAlerts(student, transactions));
      }
    } catch (e) {
      print('Error generating alerts for student: $e');
    }

    setState(() {
      alerts = generatedAlerts;
    });
  }

  List<AlertItem> _generateBudgetAlerts(AppUser student, Budget budget, List<model.Transaction> transactions) {
    List<AlertItem> budgetAlerts = [];
    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final spendingPercentage = totalSpent / budget.totalAmount;

    if (spendingPercentage >= 0.95) {
      budgetAlerts.add(AlertItem(
        id: 'budget_critical_${student.id}',
        title: 'Budget Exceeded',
        message: '${student.email} has spent ${(spendingPercentage * 100).toStringAsFixed(0)}% of their monthly budget (€${totalSpent.toStringAsFixed(2)}/€${budget.totalAmount.toStringAsFixed(2)})',
        type: AlertType.budgetExceeded,
        severity: AlertSeverity.critical,
        createdAt: DateTime.now(),
        studentEmail: student.email,
        metadata: {
          'spentAmount': totalSpent,
          'budgetAmount': budget.totalAmount,
          'percentage': spendingPercentage,
        },
      ));
    } else if (spendingPercentage >= 0.85) {
      budgetAlerts.add(AlertItem(
        id: 'budget_warning_${student.id}',
        title: 'Budget Warning',
        message: '${student.email} has spent ${(spendingPercentage * 100).toStringAsFixed(0)}% of their monthly budget',
        type: AlertType.budgetExceeded,
        severity: AlertSeverity.warning,
        createdAt: DateTime.now(),
        studentEmail: student.email,
        metadata: {
          'spentAmount': totalSpent,
          'budgetAmount': budget.totalAmount,
          'percentage': spendingPercentage,
        },
      ));
    }

    return budgetAlerts;
  }

  List<AlertItem> _generateSpendingPatternAlerts(AppUser student, List<model.Transaction> transactions) {
    List<AlertItem> patternAlerts = [];
    final now = DateTime.now();

    // Check for unusual daily spending
    final todayTransactions = transactions.where((t) =>
    t.createdAt.year == now.year &&
        t.createdAt.month == now.month &&
        t.createdAt.day == now.day).toList();

    if (todayTransactions.length >= 5) {
      final todayTotal = todayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      patternAlerts.add(AlertItem(
        id: 'daily_pattern_${student.id}',
        title: 'High Daily Activity',
        message: '${student.email} made ${todayTransactions.length} purchases today totaling €${todayTotal.toStringAsFixed(2)}',
        type: AlertType.spendingPattern,
        severity: AlertSeverity.warning,
        createdAt: DateTime.now(),
        studentEmail: student.email,
        metadata: {
          'transactionCount': todayTransactions.length,
          'totalAmount': todayTotal,
        },
      ));
    }

    // Check for weekend spending
    final weekendTransactions = transactions.where((t) =>
    t.createdAt.weekday == 6 || t.createdAt.weekday == 7).toList();

    if (weekendTransactions.length >= 3) {
      final weekendTotal = weekendTransactions.fold(0.0, (sum, t) => sum + t.amount);
      patternAlerts.add(AlertItem(
        id: 'weekend_pattern_${student.id}',
        title: 'Weekend Spending',
        message: '${student.email} has been active on weekends with ${weekendTransactions.length} transactions (€${weekendTotal.toStringAsFixed(2)})',
        type: AlertType.spendingPattern,
        severity: AlertSeverity.info,
        createdAt: DateTime.now(),
        studentEmail: student.email,
        metadata: {
          'transactionCount': weekendTransactions.length,
          'totalAmount': weekendTotal,
        },
      ));
    }

    return patternAlerts;
  }

  List<AlertItem> _generateUnusualActivityAlerts(AppUser student, List<model.Transaction> transactions) {
    List<AlertItem> unusualAlerts = [];

    // Check for large single transactions
    final largeTransactions = transactions.where((t) => t.amount > 100).toList();

    if (largeTransactions.isNotEmpty) {
      final largestTransaction = largeTransactions.first;
      unusualAlerts.add(AlertItem(
        id: 'large_transaction_${student.id}',
        title: 'Large Transaction',
        message: '${student.email} made a large purchase of €${largestTransaction.amount.toStringAsFixed(2)} on ${DateFormat('MMM dd').format(largestTransaction.createdAt)}',
        type: AlertType.unusualActivity,
        severity: AlertSeverity.warning,
        createdAt: DateTime.now(),
        studentEmail: student.email,
        metadata: {
          'transactionAmount': largestTransaction.amount,
          'transactionDate': largestTransaction.createdAt,
        },
      ));
    }

    // Check for rapid sequential transactions
    transactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (int i = 1; i < transactions.length; i++) {
      final timeDiff = transactions[i].createdAt.difference(transactions[i-1].createdAt);
      if (timeDiff.inMinutes < 5) {
        unusualAlerts.add(AlertItem(
          id: 'rapid_transactions_${student.id}',
          title: 'Rapid Transactions',
          message: '${student.email} made multiple quick purchases within 5 minutes',
          type: AlertType.unusualActivity,
          severity: AlertSeverity.info,
          createdAt: DateTime.now(),
          studentEmail: student.email,
        ));
        break;
      }
    }

    return unusualAlerts;
  }

  List<AlertItem> _generateCategoryAlerts(AppUser student, List<model.Transaction> transactions) {
    List<AlertItem> categoryAlerts = [];

    // Group transactions by category
    Map<TransactionCategory, List<model.Transaction>> categoryGroups = {};
    for (var transaction in transactions) {
      categoryGroups[transaction.category] ??= [];
      categoryGroups[transaction.category]!.add(transaction);
    }

    // Check for high spending in wants category
    final wantsTransactions = categoryGroups[TransactionCategory.wants] ?? [];
    if (wantsTransactions.isNotEmpty) {
      final wantsTotal = wantsTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
      final wantsPercentage = totalSpent > 0 ? (wantsTotal / totalSpent) * 100 : 0;

      if (wantsPercentage > 60) {
        categoryAlerts.add(AlertItem(
          id: 'wants_category_${student.id}',
          title: 'High Wants Spending',
          message: '${student.email} spent ${wantsPercentage.toStringAsFixed(0)}% of budget on wants (€${wantsTotal.toStringAsFixed(2)})',
          type: AlertType.categoryLimit,
          severity: AlertSeverity.warning,
          createdAt: DateTime.now(),
          studentEmail: student.email,
          metadata: {
            'category': 'wants',
            'amount': wantsTotal,
            'percentage': wantsPercentage,
          },
        ));
      }
    }

    return categoryAlerts;
  }

  List<AlertItem> _getFilteredAlerts() {
    switch (selectedFilter) {
      case 'Critical':
        return alerts.where((alert) => alert.severity == AlertSeverity.critical).toList();
      case 'Warning':
        return alerts.where((alert) => alert.severity == AlertSeverity.warning).toList();
      case 'Info':
        return alerts.where((alert) => alert.severity == AlertSeverity.info).toList();
      case 'Unread':
        return alerts.where((alert) => !alert.isRead).toList();
      default:
        return alerts;
    }
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.budgetExceeded:
        return Icons.account_balance_wallet;
      case AlertType.spendingPattern:
        return Icons.trending_up;
      case AlertType.unusualActivity:
        return Icons.warning;
      case AlertType.categoryLimit:
        return Icons.category;
      case AlertType.dailyLimit:
        return Icons.today;
      case AlertType.weeklyLimit:
        return Icons.date_range;
      case AlertType.monthlyLimit:
        return Icons.calendar_month;
    }
  }

  void _markAsRead(AlertItem alert) {
    setState(() {
      final index = alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        alerts[index] = AlertItem(
          id: alert.id,
          title: alert.title,
          message: alert.message,
          type: alert.type,
          severity: alert.severity,
          createdAt: alert.createdAt,
          studentEmail: alert.studentEmail,
          isRead: true,
          metadata: alert.metadata,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (context) => filterOptions.map((option) {
              return PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    if (selectedFilter == option)
                      const Icon(Icons.check, size: 16),
                    if (selectedFilter != option)
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(option),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildAlertsContent(),
      ),
    );
  }

  Widget _buildAlertsContent() {
    final filteredAlerts = _getFilteredAlerts();

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = selectedFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Alerts summary
        if (alerts.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total',
                  alerts.length.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Critical',
                  alerts.where((a) => a.severity == AlertSeverity.critical).length.toString(),
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Warning',
                  alerts.where((a) => a.severity == AlertSeverity.warning).length.toString(),
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'Unread',
                  alerts.where((a) => !a.isRead).length.toString(),
                  Colors.grey,
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Alerts list
        Expanded(
          child: filteredAlerts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredAlerts.length,
            itemBuilder: (context, index) {
              return _buildAlertCard(filteredAlerts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            selectedFilter == 'All'
                ? 'No alerts at this time'
                : 'No $selectedFilter alerts',
            style: AppTheme.subheadingStyle.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Everything looks good!',
            style: AppTheme.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final alertIcon = _getAlertIcon(alert.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(alertIcon, color: severityColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alert.title,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!alert.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alert.message,
              style: AppTheme.captionStyle,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(alert.createdAt),
                  style: AppTheme.captionStyle.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.severity.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!alert.isRead) {
            _markAsRead(alert);
          }
          _showAlertDetails(alert);
        },
      ),
    );
  }

  void _showAlertDetails(AlertItem alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.type),
              color: _getSeverityColor(alert.severity),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 16),
            Text(
              'Student: ${alert.studentEmail}',
              style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${DateFormat('MMMM dd, yyyy - HH:mm').format(alert.createdAt)}',
              style: AppTheme.captionStyle,
            ),
            if (alert.metadata != null) ...[
              const SizedBox(height: 8),
              Text(
                'Additional Info:',
                style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              ...alert.metadata!.entries.map((entry) => Text(
                '${entry.key}: ${entry.value}',
                style: AppTheme.captionStyle,
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (alert.type == AlertType.budgetExceeded)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to student progress or budget management
              },
              child: const Text('View Budget'),
            ),
        ],
      ),
    );
  }
}