import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/vehicle_service.dart';
import '../../../app/utils/vehicle_color.dart';
import '../models/vehicle_model.dart';

class HomeTabController extends GetxController {
  final _authService = Get.find<AuthService>();
  final _vehicleService = Get.find<VehicleService>();

  final residentFirstName = ''.obs;
  final vehicles = <VehicleModel>[].obs;

  StreamSubscription<List<Map<String, dynamic>>>? _vehiclesSub;

  @override
  void onInit() {
    super.onInit();
    final uid = _authService.currentUid;
    if (uid == null) return;

    _authService.fetchResidentProfile(uid).then((profile) {
      final name = (profile?['name'] as String?)?.trim();
      residentFirstName.value = (name == null || name.isEmpty) ? 'there' : name.split(' ').first;
    });

    _vehiclesSub = _vehicleService.watchVehicles(uid).listen((docs) {
      vehicles.assignAll(docs.map(_toVehicle));
    });
  }

  VehicleModel _toVehicle(Map<String, dynamic> data) {
    final colorName = data['colorName'] as String? ?? '';
    return VehicleModel(
      id: data['id'] as String,
      nickname: data['nickname'] as String? ?? '',
      makeModel: '${data['make'] ?? ''} ${data['model'] ?? ''}'.trim(),
      plateNumber: data['plateNumber'] as String? ?? '',
      color: vehicleColorForName(colorName),
      colorName: colorName,
      dateOfRegistration: data['dateOfRegistration'] as String? ?? '',
      engineNumber: data['engineNumber'] as String? ?? '',
      chassisNumber: data['chassisNumber'] as String? ?? '',
      address: data['address'] as String? ?? '',
      photoPaths: (data['photoUrls'] as List?)?.cast<String>() ?? const [],
    );
  }

  void addVehicle() {
    Get.toNamed(AppRoutes.addVehicleScan);
  }

  @override
  void onClose() {
    _vehiclesSub?.cancel();
    super.onClose();
  }
}
