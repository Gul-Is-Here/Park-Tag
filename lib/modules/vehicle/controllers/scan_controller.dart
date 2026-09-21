import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes/app_routes.dart';

class ScanController extends GetxController {
  final _picker = ImagePicker();
  final isCapturing = false.obs;

  Future<void> captureRcCard() async {
    if (isCapturing.value) return;
    isCapturing.value = true;
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return;
      Get.toNamed(AppRoutes.addVehicleReview, arguments: {'rcCardPath': photo.path});
    } finally {
      isCapturing.value = false;
    }
  }

  void enterManually() {
    Get.toNamed(AppRoutes.addVehicleReview, arguments: const {'rcCardPath': null});
  }
}
