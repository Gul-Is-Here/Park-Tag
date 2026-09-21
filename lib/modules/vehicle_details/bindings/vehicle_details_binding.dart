import 'package:get/get.dart';

import '../../dashboard/models/vehicle_model.dart';
import '../controllers/vehicle_details_controller.dart';

class VehicleDetailsBinding extends Bindings {
  @override
  void dependencies() {
    final vehicle = Get.arguments as VehicleModel;
    Get.put(VehicleDetailsController(vehicle: vehicle));
  }
}
