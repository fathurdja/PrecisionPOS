import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/order_input_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/daily_report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/delivery/delivery_dashboard_screen.dart';
import 'services/api_config.dart';
import 'widgets/bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database_helper.dart';
import 'repositories/product_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;

  // Baca dummy data via debug console
  final products = await ProductRepository().getProducts();
  print("=== DUMMY PRODUCTS ===");
  for (var p in products) {
    print("${p.id}: ${p.nama} - Rp${p.harga} (Stok: ${p.stok})");
  }
  print("======================");

  // Bypassed login temporarily for development testing
  final initialRoute = '/home';

  runApp(PrecisionPOSApp(initialRoute: initialRoute));
}

class PrecisionPOSApp extends StatelessWidget {
  final String initialRoute;

  const PrecisionPOSApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precision POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainShell(),
        '/order': (context) => const OrderInputScreen(),
        '/history': (context) => const TransactionHistoryScreen(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        if (_userRole == 'delivery') {
          return const DeliveryDashboardScreen();
        }
        return DashboardScreen(
          onNewOrder: () => Navigator.pushNamed(context, '/order'),
        );
      case 1:
        return const TransactionHistoryScreen();
      case 2:
        return const DailyReportScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
  }
}
