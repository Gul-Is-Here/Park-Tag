import 'package:parktag_app/app/services/onboarding_service.dart';

class FakeOnboardingService implements OnboardingService {
  bool seen = false;

  @override
  Future<bool> hasSeenOnboarding() async => seen;

  @override
  Future<void> markOnboardingSeen() async {
    seen = true;
  }
}
