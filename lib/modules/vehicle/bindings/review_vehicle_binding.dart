import 'package:get/get.dart';

import '../controllers/review_vehicle_controller.dart';

class ReviewVehicleBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    Get.put<ReviewVehicleController>(
      ReviewVehicleController(rcCardPath: args?['rcCardPath'] as String?),
    );
  }
}
