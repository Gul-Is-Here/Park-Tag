import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../dashboard/controllers/home_tab_controller.dart';
import '../../dashboard/models/vehicle_model.dart';

class EditVehicleController extends GetxController {
  EditVehicleController({required this.vehicle});

  static const requiredVehiclePhotos = 2;

  final VehicleModel vehicle;

  late final make = TextEditingController(text: _splitMakeModel(vehicle.makeModel).$1);
  late final model = TextEditingController(text: _splitMakeModel(vehicle.makeModel).$2);
  late final plateNumber = TextEditingController(text: vehicle.plateNumber);
  late final color = TextEditingController(text: vehicle.colorName);
  late final dateOfRegistration = TextEditingController(text: vehicle.dateOfRegistration);
  late final engineNumber = TextEditingController(text: vehicle.engineNumber);
  late final chassisNumber = TextEditingController(text: vehicle.chassisNumber);
  late final address = TextEditingController(text: vehicle.address);
  late final nickname = TextEditingController(text: vehicle.nickname);

  late final vehiclePhotos = <String>[...vehicle.photoPaths].obs;
  final isSaving = false.obs;

  final _picker = ImagePicker();

  static (String, String) _splitMakeModel(String makeModel) {
    final trimmed = makeModel.trim();
    final spaceIndex = trimmed.indexOf(' ');
    if (spaceIndex == -1) return (trimmed, '');
    return (trimmed.substring(0, spaceIndex), trimmed.substring(spaceIndex + 1));
  }

  bool get _hasRequiredFields =>
      make.text.trim().isNotEmpty &&
      model.text.trim().isNotEmpty &&
      plateNumber.text.trim().isNotEmpty;

  bool get canSave => _hasRequiredFields && vehiclePhotos.length >= requiredVehiclePhotos;

  Future<void> addVehiclePhoto(ImageSource source) async {
    if (vehiclePhotos.length >= requiredVehiclePhotos) return;
    final photo = await _picker.pickImage(source: source, imageQuality: 85);
    if (photo == null) return;
    vehiclePhotos.add(photo.path);
  }

  void removeVehiclePhoto(int index) {
    vehiclePhotos.removeAt(index);
  }

  void save() {
    if (!canSave) {
      final missing = <String>[
        if (!_hasRequiredFields) 'make, model and plate number',
        if (vehiclePhotos.length < requiredVehiclePhotos)
          '${requiredVehiclePhotos - vehiclePhotos.length} more vehicle photo(s)',
      ];
      Get.snackbar('A few things are missing', 'Please add: ${missing.join(', ')}.');
      return;
    }

    isSaving.value = true;
    final updated = VehicleModel(
      id: vehicle.id,
      nickname: nickname.text.trim().isEmpty ? plateNumber.text.trim() : nickname.text.trim(),
      makeModel: '${make.text.trim()} ${model.text.trim()}'.trim(),
      plateNumber: plateNumber.text.trim(),
      color: _swatchFor(color.text.trim()),
      colorName: color.text.trim(),
      hasUnread: vehicle.hasUnread,
      dateOfRegistration: dateOfRegistration.text.trim(),
      engineNumber: engineNumber.text.trim(),
      chassisNumber: chassisNumber.text.trim(),
      address: address.text.trim(),
      photoPaths: List.of(vehiclePhotos),
    );

    // TODO(FR-02): persist the update to Firestore/Firebase Storage.
    if (Get.isRegistered<HomeTabController>()) {
      final vehicles = Get.find<HomeTabController>().vehicles;
      final index = vehicles.indexOf(vehicle);
      if (index != -1) vehicles[index] = updated;
    }
    isSaving.value = false;

    // Pop back to the Vehicle Details screen already underneath this one on
    // the stack (it pushed us via Get.toNamed) rather than pushing a fresh
    // one — pushing a second copy left two Vehicle Details routes, and two
    // VehicleDetailsControllers, stacked at once, which crashed on the
    // duplicate QR-card GlobalKey.
    Get.back(result: updated);
    Get.snackbar('Changes saved', "${updated.nickname}'s details were updated.");
  }

  static Color _swatchFor(String name) {
    switch (name.trim().toLowerCase()) {
      case 'white':
        return const Color(0xFFF5F1E8);
      case 'black':
        return const Color(0xFF2B2B2B);
      case 'silver':
        return const Color(0xFFC2C2BE);
      case 'grey':
      case 'gray':
        return const Color(0xFF8A8A85);
      case 'red':
        return const Color(0xFFC1443C);
      case 'blue':
        return const Color(0xFF3E6FB0);
      default:
        return const Color(0xFF8A8A85);
    }
  }

  @override
  void onClose() {
    make.dispose();
    model.dispose();
    plateNumber.dispose();
    color.dispose();
    dateOfRegistration.dispose();
    engineNumber.dispose();
    chassisNumber.dispose();
    address.dispose();
    nickname.dispose();
    super.onClose();
  }
}
