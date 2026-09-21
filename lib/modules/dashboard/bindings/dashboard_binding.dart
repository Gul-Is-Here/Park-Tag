import 'package:get/get.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/home_tab_controller.dart';
import '../controllers/inbox_controller.dart';
import '../controllers/profile_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DashboardController>(DashboardController());
    Get.put<HomeTabController>(HomeTabController());
    Get.put<InboxController>(InboxController());
    Get.put<ProfileController>(ProfileController());
  }
}
