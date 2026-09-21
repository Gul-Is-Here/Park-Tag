import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';

class SignUpController extends GetxController {
  final fullName = TextEditingController();
  final phone = TextEditingController();
  final cnic = TextEditingController();
  final isSubmitting = false.obs;

  final _authService = Get.find<AuthService>();

  Future<void> sendOtp() async {
    final missing = <String>[
      if (fullName.text.trim().isEmpty) 'full name',
      if (phone.text.trim().length != 10) 'a valid phone number',
      if (cnic.text.trim().isEmpty) 'your CNIC',
    ];
    if (missing.isNotEmpty) {
      Get.snackbar('A few things are missing', 'Please add: ${missing.join(', ')}.');
      return;
    }

    final e164Phone = '+92${phone.text.trim()}';
    isSubmitting.value = true;

    final alreadyRegistered = await _authService.phoneIsRegistered(e164Phone);
    if (alreadyRegistered) {
      isSubmitting.value = false;
      Get.snackbar('Account already exists', 'This number is already registered — please log in instead.');
      return;
    }

    await _authService.sendOtp(
      e164Phone: e164Phone,
      onCodeSent: (verificationId) {
        isSubmitting.value = false;
        Get.toNamed(
          AppRoutes.otp,
          arguments: {
            'phone': phone.text.trim(),
            'verificationId': verificationId,
            'mode': 'signUp',
            'name': fullName.text.trim(),
            'cnic': cnic.text.trim(),
          },
        );
      },
      onError: (message) {
        isSubmitting.value = false;
        Get.snackbar('Could not send code', message);
      },
    );
  }

  @override
  void onClose() {
    fullName.dispose();
    phone.dispose();
    cnic.dispose();
    super.onClose();
  }
}
