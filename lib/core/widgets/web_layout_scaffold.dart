import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class WebLayoutScaffold extends StatelessWidget {
  final Widget body;
  final String title;

  const WebLayoutScaffold({
    super.key,
    required this.body,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 1,
      ),
      body: Row(
        children: [
          // Sidebar Menu
          Container(
            width: 250,
            color: Colors.white,
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Precision POS Admin',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () => Get.offNamed(AppRoutes.dashboard),
                  selected: Get.currentRoute == AppRoutes.dashboard,
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Products'),
                  onTap: () => Get.offNamed(AppRoutes.products),
                  selected: Get.currentRoute == AppRoutes.products,
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Orders'),
                  onTap: () => Get.offNamed(AppRoutes.orders),
                  selected: Get.currentRoute == AppRoutes.orders,
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Reports'),
                  onTap: () => Get.offNamed(AppRoutes.reports),
                  selected: Get.currentRoute == AppRoutes.reports,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    // TODO: Implement logout logic
                    Get.offAllNamed(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
          // Vertical Divider
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: Container(
              color: const Color(0xFFF9F9FE),
              padding: const EdgeInsets.all(24.0),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
