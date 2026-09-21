import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/services/auth_service.dart';
import 'app/services/onboarding_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Without this Firebase sends a null X-Firebase-Locale header and logs a
  // warning; it also decides what language the OTP SMS is written in.
  await FirebaseAuth.instance.setLanguageCode('en');

  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
  }

  Get.put<AuthService>(FirebaseAuthService(), permanent: true);
  Get.put<OnboardingService>(SharedPrefsOnboardingService(), permanent: true);
  runApp(const MyApp());
}
