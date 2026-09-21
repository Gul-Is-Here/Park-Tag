import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../dashboard/controllers/home_tab_controller.dart';
import '../../dashboard/models/vehicle_model.dart';

class ReviewVehicleController extends GetxController {
  ReviewVehicleController({required this.rcCardPath});

  static const requiredVehiclePhotos = 2;

  /// Path to the captured RC card photo, or null when the resident chose
  /// "Enter details manually" instead of scanning.
  final String? rcCardPath;

  final make = TextEditingController();
  final model = TextEditingController();
  final plateNumber = TextEditingController();
  final color = TextEditingController();
  final dateOfRegistration = TextEditingController();
  final engineNumber = TextEditingController();
  final chassisNumber = TextEditingController();
  final address = TextEditingController();
  final nickname = TextEditingController();

  final vehiclePhotos = <XFile>[].obs;
  final isSaving = false.obs;

  final _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    if (rcCardPath != null) {
      _applyMockOcrResult();
    }
  }

  // TODO(FR-02.1): replace with real Google ML Kit text recognition (with
  // ChatGPT Vision fallback for low-confidence reads) run against
  // rcCardPath. This stands in with sample values so the review/save flow
  // is usable end to end.
  void _applyMockOcrResult() {
    make.text = 'Toyota';
    model.text = 'Corolla Altis';
    plateNumber.text = 'LEA-2231';
    color.text = 'White';
    dateOfRegistration.text = '14 Mar 2022';
    engineNumber.text = '2ZR-4498231';
    chassisNumber.text = 'MR053CE3204119876';
    address.text = '123-B, Model Town, Lahore';
  }

  bool get _hasRequiredFields =>
      make.text.trim().isNotEmpty &&
      model.text.trim().isNotEmpty &&
      plateNumber.text.trim().isNotEmpty;

  bool get canSave =>
      _hasRequiredFields && vehiclePhotos.length >= requiredVehiclePhotos;

  Future<void> addVehiclePhoto(ImageSource source) async {
    if (vehiclePhotos.length >= requiredVehiclePhotos) return;
    final photo = await _picker.pickImage(source: source, imageQuality: 85);
    if (photo == null) return;
    vehiclePhotos.add(photo);
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
    // TODO(FR-02): persist the vehicle (and upload photos) to
    // Firestore/Firebase Storage, and generate its QR sticker (FR-03).
    // Not implemented yet — appending to the local list so the resident
    // sees the vehicle they just saved.
    if (Get.isRegistered<HomeTabController>()) {
      Get.find<HomeTabController>().vehicles.add(
        VehicleModel(
          nickname: nickname.text.trim().isEmpty ? plateNumber.text.trim() : nickname.text.trim(),
          makeModel: '${make.text.trim()} ${model.text.trim()}'.trim(),
          plateNumber: plateNumber.text.trim(),
          color: _swatchFor(color.text.trim()),
          colorName: color.text.trim(),
          dateOfRegistration: dateOfRegistration.text.trim(),
          engineNumber: engineNumber.text.trim(),
          chassisNumber: chassisNumber.text.trim(),
          address: address.text.trim(),
          photoPaths: vehiclePhotos.map((x) => x.path).toList(),
        ),
      );
    }
    isSaving.value = false;

    Get.offAllNamed(AppRoutes.dashboard);
    Get.snackbar('Vehicle saved', 'Its QR sticker will be ready on the next update.');
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
