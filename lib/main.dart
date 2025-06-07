import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/budget_controller.dart';
import 'controllers/transaction_controller.dart';
import 'controllers/theme_controller.dart'; // ✅ Make sure this file exists
import 'views/student/budget_setup_screen.dart';
import 'views/student/transaction_entry_screen.dart';
import 'views/student/dashboard_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const SmartBudgetApp());
}

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BudgetController()),
        ChangeNotifierProvider(create: (_) => TransactionController()),
        ChangeNotifierProvider(create: (_) => ThemeController()), // ✅ Added ThemeController
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Smart Budget',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme, // ✅ Properly aligned
            themeMode: themeController.themeMode, // ✅ Applies selected theme mode
            home: const StudentDashboardScreen(),
            routes: {
              '/budget-setup': (context) => const BudgetSetupScreen(),
              '/transaction-entry': (context) => const TransactionEntryScreen(),
              '/dashboard': (context) => const StudentDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
