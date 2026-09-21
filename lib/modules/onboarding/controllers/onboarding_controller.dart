import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/onboarding_service.dart';

class OnboardingController extends GetxController {
  static const pageCount = 3;

  final pageController = PageController();
  final currentPage = 0.obs;

  final _onboardingService = Get.find<OnboardingService>();

  bool get isLastPage => currentPage.value == pageCount - 1;

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (isLastPage) {
      finish();
      return;
    }
    pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void skip() => finish();

  Future<void> finish() async {
    await _onboardingService.markOnboardingSeen();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
