import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class DashboardController extends GetxController {
  static const tabCount = 3;

  final tabIndex = 0.obs;

  void changeTab(int index) {
    if (index < 0 || index >= tabCount) return;
    tabIndex.value = index;
  }

  void openScanner() {
    Get.toNamed(AppRoutes.addVehicleScan);
  }
}
