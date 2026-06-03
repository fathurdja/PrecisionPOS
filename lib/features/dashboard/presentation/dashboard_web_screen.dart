import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/web_layout_scaffold.dart';
import '../controllers/dashboard_web_controller.dart';

class DashboardWebScreen extends StatelessWidget {
  const DashboardWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardWebController());
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return WebLayoutScaffold(
      title: 'Dashboard Overview',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSummaryCard(
                  title: 'Total Sales',
                  value: currencyFormatter.format(controller.totalSales.value),
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                const SizedBox(width: 24),
                _buildSummaryCard(
                  title: 'Total Orders',
                  value: controller.totalOrders.value.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
