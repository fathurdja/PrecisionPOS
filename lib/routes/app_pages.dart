import 'package:get/get.dart';
import 'app_routes.dart';

import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_web_screen.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title)));
  }
}

class AppPages {
  static const initial = AppRoutes.dashboard;

  static final routes = [
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardWebScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const PlaceholderScreen(title: 'Login'),
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const PlaceholderScreen(title: 'Products'),
    ),
    GetPage(
      name: AppRoutes.orders,
      page: () => const PlaceholderScreen(title: 'Orders'),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const PlaceholderScreen(title: 'Reports'),
    ),
  ];
}
