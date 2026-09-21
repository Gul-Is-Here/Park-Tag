import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/auth_service.dart';
import '../../../app/services/onboarding_service.dart';

class SplashController extends GetxController {
  static const _minDisplay = Duration(seconds: 2);

  final _authService = Get.find<AuthService>();
  final _onboardingService = Get.find<OnboardingService>();

  @override
  void onReady() {
    super.onReady();
    _proceed();
  }

  Future<void> _proceed() async {
    await Future.delayed(_minDisplay);

    // A signed-in resident always lands on Dashboard, regardless of
    // onboarding state — there's no point re-showing either screen once
    // they've already registered/logged in.
    if (_authService.isSignedIn) {
      Get.offAllNamed(AppRoutes.dashboard);
      return;
    }

    final seenOnboarding = await _onboardingService.hasSeenOnboarding();
    Get.offAllNamed(seenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }
}
