import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class DashboardController extends GetxController {
  static const tabCount = 3;

  final tabIndex = 0.obs;

  void changeTab(int index) {
    if (index < 0 || index >= tabCount) return;
    tabIndex.value = index;
  }

  /// Starts the "Add vehicle" flow (RC card capture -> OCR, FR-02.1) — not
  /// to be confused with the QR scanner (top of the Home tab), which scans
  /// *another* car's ParkTag sticker to start a chat (FR-04).
  void openAddVehicle() {
    Get.toNamed(AppRoutes.addVehicleScan);
  }
}
