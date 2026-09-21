import 'package:get/get.dart';

import '../controllers/otp_controller.dart';

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    final map = args is Map ? args : const {};
    Get.put<OtpController>(
      OtpController(
        phone: (map['phone'] as String?) ?? '',
        verificationId: (map['verificationId'] as String?) ?? '',
        mode: (map['mode'] as String?) ?? 'login',
        name: map['name'] as String?,
        cnic: map['cnic'] as String?,
      ),
    );
  }
}
