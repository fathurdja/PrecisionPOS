import 'package:get/get.dart';

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
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    totalSales.value = 15500000.0;
    totalOrders.value = 120;
    isLoading.value = false;
  }
}
