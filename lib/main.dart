import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'app/services/auth_service.dart';
import 'app/services/conversation_service.dart';
import 'app/services/deep_link_service.dart';
import 'app/services/onboarding_service.dart';
import 'app/services/push_notification_service.dart';
import 'app/services/rc_ocr_service.dart';
import 'app/services/vehicle_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On web, drop the `#` from URLs so a shared `/scan/{vehicleId}` link
  // (FR-04) works without it — a no-op on mobile.
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check enforcement is on for Firestore/Functions/Storage — every
  // request needs a token attached or it's rejected outright. In debug
  // builds this uses the debug provider: on first run it prints a token to
  // the device log (logcat / Xcode console) that must be pasted into
  // Firebase Console > App Check > this app > Manage debug tokens, or every
  // request keeps failing even with this wired up. Web uses a reCAPTCHA
  // v3 site key instead — see the TODO below.
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    // TODO: swap in a real reCAPTCHA v3 site key (Firebase Console > App
    // Check > Web app > reCAPTCHA v3) before shipping the web build —
    // without it, web requests fail the same way the app was failing
    // before this fix.
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key-REPLACE-ME'),
  );

  // Must be registered before runApp so FCM can hand it background/
  // terminated-app messages. Web push needs its own service worker this
  // project doesn't have yet, so this is mobile-only (see
  // PushNotificationService.init).
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Without this Firebase sends a null X-Firebase-Locale header and logs a
  // warning; it also decides what language the OTP SMS is written in.
  await FirebaseAuth.instance.setLanguageCode('en');

  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  Get.put<AuthService>(FirebaseAuthService(), permanent: true);
  Get.put<OnboardingService>(SharedPrefsOnboardingService(), permanent: true);
  Get.put<VehicleService>(FirebaseVehicleService(), permanent: true);
  Get.put<ConversationService>(FirebaseConversationService(), permanent: true);
  Get.put<RcOcrService>(MlKitRcOcrService(), permanent: true);
  final pushService = Get.put<PushNotificationService>(
    FirebasePushNotificationService(),
    permanent: true,
  );
  await pushService.init();
  final deepLinkService = Get.put<DeepLinkService>(
    AppLinksDeepLinkService(),
    permanent: true,
  );
  await deepLinkService.init();
  runApp(const MyApp());
}
