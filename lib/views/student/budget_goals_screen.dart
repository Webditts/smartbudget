import 'package:flutter/material.dart';

class BudgetGoalsScreen extends StatefulWidget {
  @override
  _BudgetGoalsScreenState createState() => _BudgetGoalsScreenState();
}

class _BudgetGoalsScreenState extends State<BudgetGoalsScreen> {
  List<BudgetGoal> goals = [
    BudgetGoal(
      id: '1',
      title: 'Emergency Fund',
      targetAmount: 5000.0,
      currentAmount: 2350.0,
      deadline: DateTime.now().add(Duration(days: 180)),
      category: 'Savings',
      icon: Icons.security,
      color: Colors.blue,
    ),
    BudgetGoal(
      id: '2',
      title: 'Vacation to Europe',
      targetAmount: 3000.0,
      currentAmount: 750.0,
      deadline: DateTime.now().add(Duration(days: 270)),
      category: 'Travel',
      icon: Icons.flight,
      color: Colors.orange,
    ),
    BudgetGoal(
      id: '3',
      title: 'New Laptop',
      targetAmount: 1200.0,
      currentAmount: 800.0,
      deadline: DateTime.now().add(Duration(days: 60)),
      category: 'Electronics',
      icon: Icons.laptop,
      color: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Goals'),
        backgroundColor: Colors.indigo[700],
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddGoalDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return _buildGoalCard(goals[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: Colors.indigo[700],
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalTargetAmount = goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
    final totalCurrentAmount = goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
    final overallProgress = totalTargetAmount > 0 ? (totalCurrentAmount / totalTargetAmount) : 0.0;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.indigo[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Overall Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: Colors.white30,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(overallProgress * 100).toStringAsFixed(1)}% Complete',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '€${totalCurrentAmount.toStringAsFixed(0)} / €${totalTargetAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BudgetGoal goal) {
    final progress = goal.currentAmount / goal.targetAmount;
    final remainingAmount = goal.targetAmount - goal.currentAmount;
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: goal.color.withOpacity(0.1),
                  child: Icon(goal.icon, color: goal.color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        goal.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditGoalDialog(goal);
                    } else if (value == 'delete') {
                      _deleteGoal(goal);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              minHeight: 8,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '€${goal.currentAmount.toStringAsFixed(0)} / €${goal.targetAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: goal.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '$daysLeft days left',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  '€${remainingAmount.toStringAsFixed(0)} remaining',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddMoneyDialog(goal),
                    icon: Icon(Icons.add, size: 18),
                    label: Text('Add Money'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goal.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final targetAmountController = TextEditingController();
    final categoryController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: targetAmountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount (\€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Deadline'),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && targetAmountController.text.isNotEmpty) {
                setState(() {
                  goals.add(BudgetGoal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    targetAmount: double.parse(targetAmountController.text),
                    currentAmount: 0.0,
                    deadline: selectedDate,
                    category: categoryController.text.isNotEmpty ? categoryController.text : 'General',
                    icon: Icons.flag,
                    color: Colors.blue,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BudgetGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final targetAmountController = TextEditingController(text: goal.targetAmount.toString());
    final categoryController = TextEditingController(text: goal.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: targetAmountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount (\€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                goal.title = titleController.text;
                goal.targetAmount = double.parse(targetAmountController.text);
                goal.category = categoryController.text;
              });
              Navigator.pop(context);
            },
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(BudgetGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Money to ${goal.title}'),
        content: TextField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: 'Amount (\€)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                setState(() {
                  goal.currentAmount += double.parse(amountController.text);
                  if (goal.currentAmount > goal.targetAmount) {
                    goal.currentAmount = goal.targetAmount;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text('Add Money'),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(BudgetGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                goals.remove(goal);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class BudgetGoal {
  String id;
  String title;
  double targetAmount;
  double currentAmount;
  DateTime deadline;
  String category;
  IconData icon;
  Color color;

  BudgetGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.category,
    required this.icon,
    required this.color,
  });
}