import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether this device has already been through the onboarding
/// carousel, so Splash only shows it on the very first app open.
abstract class OnboardingService {
  Future<bool> hasSeenOnboarding();
  Future<void> markOnboardingSeen();
}

class SharedPrefsOnboardingService implements OnboardingService {
  static const _seenKey = 'has_seen_onboarding';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  @override
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
