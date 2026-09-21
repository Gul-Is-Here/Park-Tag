import 'package:get/get.dart';

import '../../dashboard/models/vehicle_model.dart';
import '../controllers/edit_vehicle_controller.dart';

class EditVehicleBinding extends Bindings {
  @override
  void dependencies() {
    final vehicle = Get.arguments as VehicleModel;
    Get.put(EditVehicleController(vehicle: vehicle));
  }
}
