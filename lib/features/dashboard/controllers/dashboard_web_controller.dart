import 'package:get/get.dart';
import '../../../services/api_service.dart';

class DashboardWebController extends GetxController {
  var totalSales = 0.0.obs;
  var totalOrders = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  void fetchDashboardData() async {
    isLoading.value = true;
    
    try {
      final response = await ApiService().getAnalyticsSummary();
      if (response['success']) {
        final data = response['data'];
        totalSales.value = (data['total_sales'] ?? 0.0).toDouble();
        totalOrders.value = (data['total_orders'] ?? 0).toInt();
      } else {
        Get.snackbar('Error', response['message'] ?? 'Failed to load dashboard data');
      }
    } catch (e) {
      Get.snackbar('Error', 'Network error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
