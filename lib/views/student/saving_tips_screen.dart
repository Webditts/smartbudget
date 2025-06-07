import 'package:flutter/material.dart';

class SavingTipsScreen extends StatelessWidget {
  final List<SavingTip> savingTips = [
    SavingTip(
      title: "Track Your Expenses Daily",
      description: "Monitor where your money goes by recording every expense. This awareness helps identify unnecessary spending.",
      icon: Icons.track_changes,
      category: "Budgeting",
      estimatedSavings: "10-15%",
    ),
    SavingTip(
      title: "Use the 50/30/20 Rule",
      description: "Allocate 50% for needs, 30% for wants, and 20% for savings and debt repayment.",
      icon: Icons.pie_chart,
      category: "Budgeting",
      estimatedSavings: "20%",
    ),
    SavingTip(
      title: "Cook Meals at Home",
      description: "Preparing meals at home can save significant money compared to dining out or ordering takeaway.",
      icon: Icons.restaurant_menu,
      category: "Food",
      estimatedSavings: "25-40%",
    ),
    SavingTip(
      title: "Cancel Unused Subscriptions",
      description: "Review and cancel subscriptions you don't actively use. Check monthly for streaming, gym, or app subscriptions.",
      icon: Icons.cancel,
      category: "Subscriptions",
      estimatedSavings: "5-20%",
    ),
    SavingTip(
      title: "Use Public Transportation",
      description: "Consider public transport, carpooling, or walking instead of driving when possible to save on fuel and parking.",
      icon: Icons.directions_bus,
      category: "Transportation",
      estimatedSavings: "15-30%",
    ),
    SavingTip(
      title: "Buy Generic Brands",
      description: "Choose store brands over name brands for basic items. The quality is often similar but the price is lower.",
      icon: Icons.shopping_cart,
      category: "Shopping",
      estimatedSavings: "10-25%",
    ),
    SavingTip(
      title: "Automate Your Savings",
      description: "Set up automatic transfers to your savings account right after payday to build the habit of saving first.",
      icon: Icons.savings,
      category: "Saving",
      estimatedSavings: "Variable",
    ),
    SavingTip(
      title: "Use Cashback Apps",
      description: "Take advantage of cashback and reward apps when shopping for groceries and everyday items.",
      icon: Icons.monetization_on,
      category: "Shopping",
      estimatedSavings: "2-5%",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saving Tips'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Smart Saving Tips',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Practical advice to maximize your savings',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: savingTips.length,
              itemBuilder: (context, index) {
                final tip = savingTips[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCategoryColor(tip.category),
                      child: Icon(tip.icon, color: Colors.white),
                    ),
                    title: Text(
                      tip.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      tip.category,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Save ${tip.estimatedSavings}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.description,
                              style: TextStyle(fontSize: 14, height: 1.5),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                SizedBox(width: 4),
                                Text(
                                  'Category: ${tip.category}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.trending_up, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Potential Savings: ${tip.estimatedSavings}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'budgeting':
        return Colors.blue[600]!;
      case 'food':
        return Colors.orange[600]!;
      case 'subscriptions':
        return Colors.red[600]!;
      case 'transportation':
        return Colors.purple[600]!;
      case 'shopping':
        return Colors.teal[600]!;
      case 'saving':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

class SavingTip {
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final String estimatedSavings;

  SavingTip({
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.estimatedSavings,
  });
}