import 'package:get/get.dart';

import '../controllers/comm_preference_controller.dart';

class CommPreferenceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<CommPreferenceController>(CommPreferenceController());
  }
}
