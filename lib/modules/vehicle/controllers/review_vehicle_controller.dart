import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/rc_ocr_service.dart';
import '../../../app/services/vehicle_service.dart';
import '../utils/rc_card_parser.dart';
import '../../../app/widgets/app_snackbar.dart';

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
  final isScanningRcCard = false.obs;

  /// True after a failed OCR attempt (couldn't read the photo at all, e.g.
  /// a processing error) — drives a "Retry scan" affordance on the Review
  /// screen, separate from just leaving fields editable for manual entry.
  final ocrFailed = false.obs;

  final _picker = ImagePicker();
  final _authService = Get.find<AuthService>();
  final _vehicleService = Get.find<VehicleService>();
  final _ocrService = Get.find<RcOcrService>();

  @override
  void onInit() {
    super.onInit();
    final path = rcCardPath;
    if (path != null) {
      _runOcr(path);
    }
  }

  /// FR-02.1: reads the captured RC card photo on-device with Google ML
  /// Kit, then applies best-effort field extraction (see
  /// [parseRcCardText]) — every field it fills stays editable below, since
  /// OCR on a photographed card is never guaranteed to be exact.
  Future<void> _runOcr(String path) async {
    isScanningRcCard.value = true;
    ocrFailed.value = false;
    try {
      final recognizedText = await _ocrService.recognizeText(path);
      final fields = parseRcCardText(recognizedText);

      if (fields.make != null) make.text = fields.make!;
      if (fields.model != null) model.text = fields.model!;
      if (fields.plateNumber != null) plateNumber.text = fields.plateNumber!;
      if (fields.color != null) color.text = fields.color!;
      if (fields.dateOfRegistration != null) dateOfRegistration.text = fields.dateOfRegistration!;
      if (fields.engineNumber != null) engineNumber.text = fields.engineNumber!;
      if (fields.chassisNumber != null) chassisNumber.text = fields.chassisNumber!;
      if (fields.address != null) address.text = fields.address!;

      if (fields.make == null && fields.plateNumber == null && fields.chassisNumber == null) {
        AppSnackbar.show(
          "Couldn't read much from that photo",
          'Please check the fields below and fill in anything missing.',
        );
      }
    } catch (_) {
      ocrFailed.value = true;
      AppSnackbar.show('Scan failed', 'Retry the scan, or fill in the details manually below.');
    } finally {
      isScanningRcCard.value = false;
    }
  }

  /// Re-runs OCR against the same captured photo — the "Retry scan"
  /// affordance shown when [_runOcr] fails outright. Manual editing of
  /// every field below remains available regardless.
  Future<void> retryOcrScan() {
    final path = rcCardPath;
    if (path == null) return Future.value();
    return _runOcr(path);
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

  Future<void> save() async {
    if (!canSave) {
      final missing = <String>[
        if (!_hasRequiredFields) 'make, model and plate number',
        if (vehiclePhotos.length < requiredVehiclePhotos)
          '${requiredVehiclePhotos - vehiclePhotos.length} more vehicle photo(s)',
      ];
      AppSnackbar.show('A few things are missing', 'Please add: ${missing.join(', ')}.');
      return;
    }

    final uid = _authService.currentUid;
    if (uid == null) {
      AppSnackbar.show('Not signed in', 'Please log in again and retry.');
      return;
    }

    isSaving.value = true;
    try {
      final profile = await _authService.fetchResidentProfile(uid);
      final ownerName = (profile?['name'] as String?)?.trim();
      final localPhotoPaths = vehiclePhotos.map((x) => x.path).toList();
      await _vehicleService.saveVehicle(
        uid: uid,
        ownerName: (ownerName == null || ownerName.isEmpty) ? 'A ParkTag resident' : ownerName,
        nickname: nickname.text.trim().isEmpty ? plateNumber.text.trim() : nickname.text.trim(),
        make: make.text.trim(),
        model: model.text.trim(),
        plateNumber: plateNumber.text.trim(),
        colorName: color.text.trim(),
        dateOfRegistration: dateOfRegistration.text.trim(),
        engineNumber: engineNumber.text.trim(),
        chassisNumber: chassisNumber.text.trim(),
        address: address.text.trim(),
        localPhotoPaths: localPhotoPaths,
      );

      // HomeTabController streams straight from Firestore (watchVehicles),
      // so the new vehicle appears on the Home tab on its own — no local
      // list to update here.
      isSaving.value = false;
      Get.offAllNamed(AppRoutes.dashboard);
      AppSnackbar.show('Vehicle saved', 'Its QR sticker is ready — open the vehicle to view or share it.');
    } catch (_) {
      isSaving.value = false;
      AppSnackbar.show('Could not save vehicle', 'Something went wrong. Please try again.');
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
