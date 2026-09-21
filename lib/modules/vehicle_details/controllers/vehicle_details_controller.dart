import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../dashboard/controllers/home_tab_controller.dart';
import '../../dashboard/models/vehicle_model.dart';
import '../widgets/remove_vehicle_dialog.dart';

class VehicleDetailsController extends GetxController {
  VehicleDetailsController({required this.vehicle});

  final VehicleModel vehicle;

  void editVehicle() {
    Get.toNamed(AppRoutes.editVehicle, arguments: vehicle);
  }

  Future<void> removeVehicle() async {
    final confirmed = await Get.dialog<bool>(
      RemoveVehicleDialog(nickname: vehicle.nickname),
    );
    if (confirmed != true) return;

    if (Get.isRegistered<HomeTabController>()) {
      Get.find<HomeTabController>().vehicles.remove(vehicle);
    }
    Get.back();
    Get.snackbar('Vehicle removed', '${vehicle.nickname} was removed from your vehicles.');
  }
}
