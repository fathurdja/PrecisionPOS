import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/order_input_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/daily_report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/delivery/delivery_dashboard_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'data/database_helper.dart';
import 'repositories/product_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Requires flutterfire configure to be fully functional)
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
    } else {
      // Firebase Web requires options to initialize from Dart, which is handled after running `flutterfire configure`.
      // We log it but do not throw to allow the web app to run.
      debugPrint("Firebase Web: Please run `flutterfire configure` to set up FirebaseOptions.");
    }
  } catch (e) {
    debugPrint("Firebase initialization failed or not configured yet: $e");
  }

  if (!kIsWeb) {
    await DatabaseHelper.instance.database;

    // Baca dummy data via debug console
    final products = await ProductRepository().getProducts();
    print("=== DUMMY PRODUCTS ===");
    for (var p in products) {
      print("${p.id}: ${p.nama} - Rp${p.harga} (Stok: ${p.stok})");
    }
    print("======================");
  }

  // Check if user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  String initialRoute = (token != null && token.isNotEmpty) ? '/home' : '/login';

  if (kIsWeb) {
    // For web, use the GetX routes
    initialRoute = (token != null && token.isNotEmpty) ? AppRoutes.dashboard : AppRoutes.login;
  }

  runApp(PrecisionPOSApp(initialRoute: initialRoute));
}

class PrecisionPOSApp extends StatelessWidget {
  final String initialRoute;

  const PrecisionPOSApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Precision POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
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
  bool _isRoleLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('user_role') ?? 'admin';
        _isRoleLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRoleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FE),
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        userRole: _userRole,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  /// Maps the current tab index to the correct screen based on the
  /// user's role. Uses [AppBottomNavBar.getTabsForRole] to get the
  /// ordered list of tab keys, then resolves each key to a widget.
  Widget _buildBody() {
    final tabs = AppBottomNavBar.getTabsForRole(_userRole);
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);
    final activeKey = tabs[safeIndex].key;

    switch (activeKey) {
      case 'sales':
        return DashboardScreen(
          onNewOrder: () => Navigator.pushNamed(context, '/order'),
        );
      case 'order':
        return const OrderInputScreen();
      case 'history':
        return const TransactionHistoryScreen();
      case 'reports':
        return const DailyReportScreen();
      case 'settings':
        return const SettingsScreen();
      case 'delivery':
        return const DeliveryDashboardScreen();
      default:
        return DashboardScreen(
          onNewOrder: () => Navigator.pushNamed(context, '/order'),
        );
    }
  }
}
