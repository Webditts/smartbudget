import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartbudget/models/transaction_model.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/budget_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../student/budget_analytics_screen.dart';
import '../student/spending_alerts_screen.dart';
import '../student/student_progress_screen.dart';

class StudentData {
  final AppUser user;
  final Budget? budget;
  final List<model.Transaction> transactions;

  StudentData({
    required this.user,
    this.budget,
    required this.transactions,
  });
}

class AlertData {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String time;

  AlertData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
  });
}

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  String selectedTimeframe = 'This Month';
  List<StudentData> connectedStudents = [];
  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final parentUser = authController.currentUser;

      if (parentUser?.studentEmail != null) {
        // Find the student user by email
        final studentQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: parentUser!.studentEmail)
            .where('role', isEqualTo: 'UserRole.student')
            .get();

        if (studentQuery.docs.isNotEmpty) {
          final studentDoc = studentQuery.docs.first;
          final studentUser = AppUser.fromJson(studentDoc.data());

          // Load student's budget and transactions
          final studentData = await _loadStudentBudgetAndTransactions(studentUser);

          setState(() {
            connectedStudents = [studentData];
            isLoading = false;
          });
        } else {
          setState(() {
            connectedStudents = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          connectedStudents = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<StudentData> _loadStudentBudgetAndTransactions(AppUser student) async {
    try {
      // Get student's current budget
      final budgetQuery = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: student.id)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      Budget? currentBudget;
      List<model.Transaction> transactions = [];

      if (budgetQuery.docs.isNotEmpty) {
        currentBudget = Budget.fromJson(budgetQuery.docs.first.data());

        // Get transactions for this budget
        final transactionQuery = await _firestore
            .collection('transactions')
            .where('budgetId', isEqualTo: currentBudget.id)
            .orderBy('createdAt', descending: true)
            .get();

        transactions = transactionQuery.docs
            .map((doc) => model.Transaction.fromJson(doc.data()))
            .toList();
      }

      return StudentData(
        user: student,
        budget: currentBudget,
        transactions: transactions,
      );
    } catch (e) {
      print('Error loading student budget and transactions: $e');
      return StudentData(
        user: student,
        budget: null,
        transactions: [],
      );
    }
  }

  // Helper method to get budget health color
  Color _getBudgetHealthColor(double spendingRatio) {
    if (spendingRatio >= 0.9) return Colors.red;
    if (spendingRatio >= 0.7) return Colors.orange;
    return Colors.green;
  }

  // Helper method to get health status text
  String _getHealthStatus(double spendingRatio) {
    if (spendingRatio >= 0.9) return 'Critical';
    if (spendingRatio >= 0.7) return 'Warning';
    return 'Good';
  }

  // Helper method to get category color
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

  // Helper method to get category icon
  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.needs:
        return Icons.shopping_basket;
      case TransactionCategory.wants:
        return Icons.shopping_bag;
      case TransactionCategory.emergency:
        return Icons.warning;
      default:
        return Icons.category;
    }
  }

  // Dialog methods
  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
        content: const Text('Feature coming soon. Students can connect by sharing their email with parents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showParentSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parent Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Preferences'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add privacy settings logic
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSetLimitsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Spending Limits'),
        content: const Text('Feature coming soon. You will be able to set daily, weekly, and monthly spending limits for your students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Budget Alerts'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Spending Notifications'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Weekly Reports'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBlockCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Categories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Entertainment'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Gaming'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Fast Food'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SpendingAlertsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add_student':
                  _showAddStudentDialog();
                  break;
                case 'settings':
                  _showParentSettingsDialog(context);
                  break;
                case 'reports':
                // Check if there's a connected student with budget data
                  if (connectedStudents.isNotEmpty && connectedStudents.first.budget != null) {
                    final student = connectedStudents.first;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BudgetAnalyticsScreen(
                          studentUserId: student.user.id,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No student data available for reports.'),
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'add_student',
                child: Row(
                  children: [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text('Add Student'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Detailed Reports'),
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
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          // Verify user is a parent
          if (authController.currentUser?.role != UserRole.parent) {
            return const Center(
              child: Text('Access Denied: Parent role required'),
            );
          }

          return _buildParentDashboardContent();
        },
      ),
    );
  }

  Widget _buildParentDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message for parents
            _buildWelcomeSection(),
            const SizedBox(height: 16),

            // Timeframe selector
            _buildTimeframeSelector(),
            const SizedBox(height: 16),

            // Students overview cards
            _buildStudentsOverview(),
            const SizedBox(height: 16),

            // Spending alerts
            _buildSpendingAlerts(),
            const SizedBox(height: 16),

            // Recent activities across all students
            _buildRecentActivities(),
            const SizedBox(height: 16),

            // Category trends
            _buildCategoryTrends(),
            const SizedBox(height: 16),

            // Parent controls
            _buildParentControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  radius: 25,
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.email ?? 'Parent'}!',
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.studentEmail != null
                            ? 'Monitoring: ${user!.studentEmail}'
                            : 'No student connected',
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'PARENT',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeframeChip('This Week'),
          _buildTimeframeChip('This Month'),
          _buildTimeframeChip('Last 3 Months'),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String timeframe) {
    final isSelected = selectedTimeframe == timeframe;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTimeframe = timeframe;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
          ),
        ),
        child: Text(
          timeframe,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Students Overview',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),

        // Show loading indicator
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )

        // Show card when no students are connected
        else if (connectedStudents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.group_add,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students connected',
                    style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a student to monitor their budget',
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
          )

        // Show list of student cards
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: connectedStudents.length,
              itemBuilder: (context, index) {
                return _buildStudentCard(connectedStudents[index]);
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentCard(StudentData studentData) {
    final budget = studentData.budget;
    final transactions = studentData.transactions;
    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final budgetLimit = budget?.totalAmount ?? 0.0;
    final spendingRatio = budgetLimit > 0 ? totalSpent / budgetLimit : 0.0;
    final healthColor = _getBudgetHealthColor(spendingRatio);

    return Container(
      width: 280,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Avatar and email
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          studentData.user.email.substring(0, 2).toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentData.user.email,
                            style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            budget != null ? 'Active budget' : 'No budget',
                            style: AppTheme.captionStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Spending status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: healthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getHealthStatus(spendingRatio),
                      style: TextStyle(
                        color: healthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Budget details or message if none
              if (budget != null) ...[
                // Spent and budget summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spent', style: AppTheme.captionStyle),
                        Text(
                          '€${totalSpent.toStringAsFixed(2)}',
                          style: AppTheme.amountStyle.copyWith(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Budget', style: AppTheme.captionStyle),
                        Text(
                          '€${budgetLimit.toStringAsFixed(2)}',
                          style: AppTheme.amountStyle.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                LinearProgressIndicator(
                  value: spendingRatio.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),

                const SizedBox(height: 8),

                // Button and percentage left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentProgressScreen(
                              studentName: studentData.user.email,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                    Text(
                      '${((1 - spendingRatio) * 100).clamp(0, 100).toStringAsFixed(0)}% left',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ] else ...[
                const Center(
                  child: Text(
                    'No budget created yet',
                    style: AppTheme.captionStyle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSpendingAlerts() {
    List<AlertData> alerts = [];

    // Generate alerts based on student data
    for (var student in connectedStudents) {
      if (student.budget != null) {
        final totalSpent = student.transactions.fold(0.0, (sum, t) => sum + t.amount);
        final spendingPercentage = totalSpent / student.budget!.totalAmount;

        if (spendingPercentage >= 0.85) {
          alerts.add(AlertData(
            title: 'Budget Warning',
            message: '${student.user.email} has spent ${(spendingPercentage * 100).toStringAsFixed(0)}% of monthly budget',
            icon: Icons.warning,
            color: Colors.orange,
            time: 'Recent',
          ));
        }

        // Check for unusual spending patterns
        final recentTransactions = student.transactions
            .where((t) => t.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1))))
            .toList();

        if (recentTransactions.length >= 3) {
          alerts.add(AlertData(
            title: 'Unusual Spending',
            message: '${student.user.email} made ${recentTransactions.length} purchases today',
            icon: Icons.info,
            color: Colors.blue,
            time: 'Today',
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spending Alerts',
              style: AppTheme.subheadingStyle,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpendingAlertsScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (alerts.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts at this time',
                    style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...alerts.take(3).map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildAlertCard(
              alert.title,
              alert.message,
              alert.icon,
              alert.color,
              alert.time,
            ),
          )),
      ],
    );
  }

  Widget _buildAlertCard(String title, String message, IconData icon, Color color, String time) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: AppTheme.captionStyle),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTheme.captionStyle.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    List<model.Transaction> allTransactions = [];

    for (var student in connectedStudents) {
      allTransactions.addAll(student.transactions);
    }

    allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentTransactions = allTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),
        if (recentTransactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activities',
                    style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...recentTransactions.map((transaction) => _buildActivityTile(transaction)),
      ],
    );
  }

  Widget _buildActivityTile(model.Transaction transaction) {
    final categoryColor = _getCategoryColor(transaction.category);
    final categoryIcon = _getCategoryIcon(transaction.category);

    // Find which student this transaction belongs to
    String studentEmail = '';
    for (var student in connectedStudents) {
      if (student.transactions.contains(transaction)) {
        studentEmail = student.user.email;
        break;
      }
    }

    return Card(
        margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
    leading: CircleAvatar(
    backgroundColor: categoryColor.withOpacity(0.1),
    child: Icon(categoryIcon, color: categoryColor, size: 20),
    ),
    title: Row(
    children: [
    Expanded(
    child: Text(
    studentEmail,
    style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
    overflow: TextOverflow.ellipsis,
    ),
    ),
    const SizedBox(width: 8),
    Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
    color: categoryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
    transaction.category.toString().split('.').last,
    style: TextStyle(
    color: categoryColor,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ],
    ),
    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    transaction.description ?? 'No description',
    style: AppTheme.captionStyle,
    ),
    Text(
      DateFormat('MMM dd, yyyy - HH:mm').format(transaction.createdAt),
      style: AppTheme.captionStyle.copyWith(color: Colors.grey),
    ),
    ],
    ),
      trailing: Text(
        '-€${transaction.amount.toStringAsFixed(2)}',
        style: AppTheme.amountStyle.copyWith(
          color: AppTheme.errorColor,
          fontSize: 16,
        ),
      ),
    ),
    );
  }

  Widget _buildCategoryTrends() {
    Map<TransactionCategory, double> categoryTotals = {};

    for (var student in connectedStudents) {
      for (var transaction in student.transactions) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Trends',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),
        if (categoryTotals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No spending data available',
                    style: AppTheme.bodyStyle.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: categoryTotals.entries.map((entry) {
                  final category = entry.key;
                  final amount = entry.value;
                  final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);
                  final percentage = total > 0 ? (amount / total) * 100 : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.toString().split('.').last.toUpperCase(),
                            style: AppTheme.bodyStyle,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${amount.toStringAsFixed(2)}',
                              style: AppTheme.amountStyle.copyWith(fontSize: 14),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: AppTheme.captionStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildParentControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parent Controls',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: _showSetLimitsDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Set Limits',
                          style: AppTheme.bodyStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: _showBlockCategoriesDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.block,
                          size: 32,
                          color: AppTheme.errorColor,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Block Categories',
                          style: AppTheme.bodyStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}