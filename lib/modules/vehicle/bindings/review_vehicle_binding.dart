import 'package:get/get.dart';

import '../controllers/review_vehicle_controller.dart';

class ReviewVehicleBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    Get.put<ReviewVehicleController>(
      ReviewVehicleController(
        frontImagePath: args?['frontImagePath'] as String?,
        backImagePath: args?['backImagePath'] as String?,
      ),
    );
  }
}
