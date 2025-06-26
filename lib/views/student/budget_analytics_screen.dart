// views/student/budget_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../../controllers/budget_controller.dart';
import '../../models/transaction_model.dart';
import '../../widgets/category_trend_chart.dart';

class BudgetAnalyticsScreen extends StatefulWidget {
  @override
  _BudgetAnalyticsScreenState createState() => _BudgetAnalyticsScreenState();
}

class _BudgetAnalyticsScreenState extends State<BudgetAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetController>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Analytics'),
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.pie_chart), text: 'Overview'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trends'),
            Tab(icon: Icon(Icons.analytics), text: 'Insights'),
          ],
        ),
      ),
      body: Consumer<BudgetController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (controller.currentBudget == null) {
            return _buildNoBudgetView();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(controller),
              _buildTrendsTab(controller),
              _buildInsightsTab(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoBudgetView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No Budget Data', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 8),
          Text('Create a budget and add transactions to see analytics'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            child: Text('Create Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BudgetController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Budget Distribution Pie Chart
          _buildBudgetDistributionChart(controller),
          SizedBox(height: 16),

          // Spending vs Budget Chart
          _buildSpendingComparisonChart(controller),
          SizedBox(height: 16),

          // Category Performance Cards
          _buildCategoryPerformanceCards(controller),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(BudgetController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Daily Spending Trend
          _buildDailySpendingChart(controller),
          SizedBox(height: 16),

          // Category Spending Over Time
          _buildCategoryTrendChart(controller),
          SizedBox(height: 16),

          // Spending Pattern Analysis
          _buildSpendingPatternCard(controller),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(BudgetController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Budget Health Score
          _buildBudgetHealthScore(controller),
          SizedBox(height: 16),

          // Smart Recommendations
          _buildSmartRecommendations(controller),
          SizedBox(height: 16),

          // Spending Habits Analysis
          _buildSpendingHabitsCard(controller),
          SizedBox(height: 16),

          // Achievement Badges
          _buildAchievementBadges(controller),
        ],
      ),
    );
  }

  Widget _buildBudgetDistributionChart(BudgetController controller) {
    final budget = controller.currentBudget!;

    final data = [
      BudgetCategoryData('Needs', budget.needsAmount, Colors.blue),
      BudgetCategoryData('Wants', budget.wantsAmount, Colors.green),
      BudgetCategoryData('Emergency', budget.emergencyAmount, Colors.red),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomPieChart(data: data),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: data.map((item) => _buildLegendItem(
                        item.category,
                        item.amount,
                        item.color,
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingComparisonChart(BudgetController controller) {
    final budget = controller.currentBudget!;

    final data = [
      CategorySpendingData('Needs', controller.needsSpent, budget.needsAmount),
      CategorySpendingData('Wants', controller.wantsSpent, budget.wantsAmount),
      CategorySpendingData('Emergency', controller.emergencySpent, budget.emergencyAmount),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending vs Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: CustomBarChart(data: data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPerformanceCards(BudgetController controller) {
    return Column(
      children: [
        _buildPerformanceCard(
          'Needs',
          controller.needsSpent,
          controller.currentBudget!.needsAmount,
          Icons.shopping_basket,
          Colors.blue,
        ),
        SizedBox(height: 8),
        _buildPerformanceCard(
          'Wants',
          controller.wantsSpent,
          controller.currentBudget!.wantsAmount,
          Icons.shopping_bag,
          Colors.green,
        ),
        SizedBox(height: 8),
        _buildPerformanceCard(
          'Emergency',
          controller.emergencySpent,
          controller.currentBudget!.emergencyAmount,
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(String category, double spent, double budget, IconData icon, Color color) {
    final percentage = budget > 0 ? (spent / budget * 100) : 0;
    final remaining = budget - spent;
    final isOverBudget = spent > budget;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '€{spent.toStringAsFixed(2)} of €{budget.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? Colors.red : color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : color,
                  ),
                ),
                Text(
                  isOverBudget ? 'Over by €{(-remaining).toStringAsFixed(2)}' : '€{remaining.toStringAsFixed(2)} left',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverBudget ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySpendingChart(BudgetController controller) {
    final dailyData = _calculateDailySpending(controller.transactions);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Spending Trend (Last 7 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: DailySpendingChart(data: dailyData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTrendChart(BudgetController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Spending Over Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: CategoryTrendChart(transactions: controller.transactions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingPatternCard(BudgetController controller) {
    final patterns = _analyzeSpendingPatterns(controller.transactions);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Patterns',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            ...patterns.map((pattern) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(pattern.icon, size: 20, color: pattern.color),
                  SizedBox(width: 12),
                  Expanded(child: Text(pattern.description)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetHealthScore(BudgetController controller) {
    final score = _calculateBudgetHealthScore(controller);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Budget Health Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(score),
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              _getScoreDescription(score),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartRecommendations(BudgetController controller) {
    final recommendations = _generateRecommendations(controller);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Recommendations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            ...recommendations.map((rec) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rec.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rec.color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(rec.icon, color: rec.color),
                  SizedBox(width: 12),
                  Expanded(child: Text(rec.message)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingHabitsCard(BudgetController controller) {
    final habits = _analyzeSpendingHabits(controller.transactions);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Habits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            ...habits.map((habit) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: habit.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(habit.icon, size: 20, color: habit.color),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadges(BudgetController controller) {
    final achievements = _calculateAchievements(controller);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: achievement.earned ? achievement.color.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: achievement.earned ? achievement.color : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      achievement.icon,
                      size: 16,
                      color: achievement.earned ? achievement.color : Colors.grey,
                    ),
                    SizedBox(width: 6),
                    Text(
                      achievement.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: achievement.earned ? achievement.color : Colors.grey,
                        fontWeight: achievement.earned ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double amount, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '€{amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for calculations and data processing
  List<DailySpendingData> _calculateDailySpending(List<Transaction> transactions) {
    final now = DateTime.now();
    final data = <DailySpendingData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayTransactions = transactions.where((t) =>
      t.createdAt.year == date.year &&
          t.createdAt.month == date.month &&
          t.createdAt.day == date.day
      );

      final totalSpent = dayTransactions.fold(0.0, (sum, t) => sum + t.amount);
      data.add(DailySpendingData(date, totalSpent));
    }

    return data;
  }

  List<SpendingPattern> _analyzeSpendingPatterns(List<Transaction> transactions) {
    final patterns = <SpendingPattern>[];

    if (transactions.isEmpty) return patterns;

    // Most active spending day
    final daySpending = <int, double>{};
    for (final transaction in transactions) {
      final weekday = transaction.createdAt.weekday;
      daySpending[weekday] = (daySpending[weekday] ?? 0) + transaction.amount;
    }

    final mostActiveDay = daySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    patterns.add(SpendingPattern(
      'Most active spending day: ${dayNames[mostActiveDay.key - 1]}',
      Icons.calendar_today,
      Colors.blue,
    ));

    // Average transaction amount
    final avgAmount = transactions.fold(0.0, (sum, t) => sum + t.amount) / transactions.length;
    patterns.add(SpendingPattern(
      'Average transaction: €{avgAmount.toStringAsFixed(2)}',
      Icons.monetization_on,
      Colors.green,
    ));

    // Most frequent category
    final categoryCount = <TransactionCategory, int>{};
    for (final transaction in transactions) {
      categoryCount[transaction.category] = (categoryCount[transaction.category] ?? 0) + 1;
    }

    if (categoryCount.isNotEmpty) {
      final mostFrequent = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b);
      patterns.add(SpendingPattern(
        'Most frequent category: ${mostFrequent.key.name.toUpperCase()}',
        Icons.category,
        Colors.orange,
      ));
    }

    return patterns;
  }

  double _calculateBudgetHealthScore(BudgetController controller) {
    if (controller.currentBudget == null) return 0;

    final budget = controller.currentBudget!;
    final totalSpent = controller.totalSpent;
    final totalBudget = budget.totalAmount;

    // Base score starts at 100
    double score = 100;

    // Penalize for overspending
    if (totalSpent > totalBudget) {
      score -= ((totalSpent - totalBudget) / totalBudget) * 50;
    }

    // Reward for staying within budget
    final spentPercentage = totalSpent / totalBudget;
    if (spentPercentage <= 0.8) {
      score += 10; // Bonus for staying well within budget
    }

    // Penalize for unbalanced spending
    final categories = ['needs', 'wants', 'emergency'];
    for (final category in categories) {
      final spent = controller.transactions
          .where((t) => t.category == category)
          .fold(0.0, (sum, t) => sum + t.amount);
      final budgetAmount = category == 'needs' ? budget.needsAmount :
      category == 'wants' ? budget.wantsAmount :
      budget.emergencyAmount;

      if (spent > budgetAmount) {
        score -= ((spent - budgetAmount) / budgetAmount) * 15;
      }
    }

    return score.clamp(0, 100);
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 80) return 'Excellent budget management!';
    if (score >= 60) return 'Good, but room for improvement';
    return 'Need to improve spending habits';
  }

  List<Recommendation> _generateRecommendations(BudgetController controller) {
    final recommendations = <Recommendation>[];

    // Check for overspending in categories
    if (controller.needsSpent > controller.currentBudget!.needsAmount) {
      recommendations.add(Recommendation(
        'Consider reducing spending on needs or increasing this category budget',
        Icons.warning,
        Colors.orange,
      ));
    }

    if (controller.wantsSpent > controller.currentBudget!.wantsAmount) {
      recommendations.add(Recommendation(
        'You\'re overspending on wants. Try to prioritize essential purchases',
        Icons.shopping_bag,
        Colors.red,
      ));
    }

    // Check for emergency fund usage
    if (controller.emergencySpent > 0) {
      recommendations.add(Recommendation(
        'You\'ve used emergency funds. Consider replenishing when possible',
        Icons.savings,
        Colors.blue,
      ));
    }

    // Positive reinforcement
    if (controller.totalSpent < controller.currentBudget!.totalAmount * 0.8) {
      recommendations.add(Recommendation(
        'Great job staying within budget! Consider saving the extra money',
        Icons.thumb_up,
        Colors.green,
      ));
    }

    return recommendations;
  }

  List<SpendingHabit> _analyzeSpendingHabits(List<Transaction> transactions) {
    final habits = <SpendingHabit>[];

    if (transactions.isEmpty) return habits;

    // Analyze spending frequency
    final now = DateTime.now();
    final recentTransactions = transactions.where((t) =>
    now.difference(t.createdAt).inDays <= 7
    ).length;

    habits.add(SpendingHabit(
      'Transaction Frequency',
      '$recentTransactions transactions in the last 7 days',
      Icons.timeline,
      Colors.blue,
    ));

    // Analyze spending consistency
    final dailyAmounts = <String, double>{};
    for (final transaction in transactions) {
      final dateKey = '${transaction.createdAt.year}-${transaction.createdAt.month}-${transaction.createdAt.day}';
      dailyAmounts[dateKey] = (dailyAmounts[dateKey] ?? 0) + transaction.amount;
    }

    if (dailyAmounts.isNotEmpty) {
      final avgDaily = dailyAmounts.values.reduce((a, b) => a + b) / dailyAmounts.length;
      habits.add(SpendingHabit(
        'Daily Average',
        '€{avgDaily.toStringAsFixed(2)} per active day',
        Icons.trending_up,
        Colors.green,
      ));
    }

    return habits;
  }

  List<Achievement> _calculateAchievements(BudgetController controller) {
    final achievements = <Achievement>[];

    // First transaction
    achievements.add(Achievement(
      'First Step',
      Icons.star,
      Colors.yellow,
      controller.transactions.isNotEmpty,
    ));

    // Week without overspending
    final weeklyOverspend = controller.totalSpent <= controller.currentBudget!.totalAmount;
    achievements.add(Achievement(
      'Budget Keeper',
      Icons.shield,
      Colors.blue,
      weeklyOverspend,
    ));

    // 10 transactions
    achievements.add(Achievement(
      'Active Tracker',
      Icons.show_chart,
      Colors.green,
      controller.transactions.length >= 10,
    ));

    // Emergency fund unused
    achievements.add(Achievement(
      'Emergency Saver',
      Icons.savings,
      Colors.orange,
      controller.emergencySpent == 0,
    ));

    return achievements;
  }
}

// Data models for charts
class BudgetCategoryData {
  final String category;
  final double amount;
  final Color color;

  BudgetCategoryData(this.category, this.amount, this.color);
}

class CategorySpendingData {
  final String category;
  final double spent;
  final double budget;

  CategorySpendingData(this.category, this.spent, this.budget);
}

class DailySpendingData {
  final DateTime date;
  final double amount;

  DailySpendingData(this.date, this.amount);
}

class SpendingPattern {
  final String description;
  final IconData icon;
  final Color color;

  SpendingPattern(this.description, this.icon, this.color);
}

class Recommendation {
  final String message;
  final IconData icon;
  final Color color;

  Recommendation(this.message, this.icon, this.color);
}

class SpendingHabit {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  SpendingHabit(this.title, this.description, this.icon, this.color);
}

class Achievement {
  final String title;
  final IconData icon;
  final Color color;
  final bool earned;

  Achievement(this.title, this.icon, this.color, this.earned);
}

// Custom chart widgets (simplified implementations)
class CustomPieChart extends StatelessWidget {
  final List<BudgetCategoryData> data;

  const CustomPieChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        painter: PieChartPainter(data),
        child: Container(),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<BudgetCategoryData> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final total = data.fold(0.0, (sum, item) => sum + item.amount);

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (final item in data) {
      final sweepAngle = (item.amount / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CustomBarChart extends StatelessWidget {
  final List<CategorySpendingData> data;

  const CustomBarChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        painter: BarChartPainter(data),
        child: Container(),
      ),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<CategorySpendingData> data;

  BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.fold(0.0, (max, item) =>
    max > item.budget ? max : item.budget);

    final barWidth = size.width / (data.length * 2);
    final colors = [Colors.blue, Colors.green, Colors.red];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final x = (i * 2 + 0.5) * barWidth;

      // Budget bar (background)
      final budgetHeight = (item.budget / maxValue) * size.height * 0.8;
      final budgetRect = Rect.fromLTWH(
          x,
          size.height - budgetHeight,
          barWidth,
          budgetHeight
      );

      canvas.drawRect(
        budgetRect,
        Paint()..color = colors[i].withOpacity(0.3),
      );

      // Spent bar (foreground)
      final spentHeight = (item.spent / maxValue) * size.height * 0.8;
      final spentRect = Rect.fromLTWH(
          x,
          size.height - spentHeight,
          barWidth,
          spentHeight
      );

      canvas.drawRect(
        spentRect,
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DailySpendingChart extends StatelessWidget {
  final List<DailySpendingData> data;

  const DailySpendingChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        painter: LineChartPainter(data),
        child: Container(),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<DailySpendingData> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.fold(0.0, (max, item) => max > item.amount ? max : item.amount);
    if (maxValue == 0) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].amount / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}