import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/routes/app_pages.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/onboarding_service.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_onboarding_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(Get.reset);

  Future<void> pumpSplash(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump();
  }

  testWidgets('Splash screen renders wordmark', (tester) async {
    Get.put<AuthService>(FakeAuthService());
    Get.put<OnboardingService>(FakeOnboardingService());

    await pumpSplash(tester);

    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText() == 'ParkTag',
      ),
      findsOneWidget,
    );
    expect(find.text('Scan. Message. Move on.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Flush the SplashController's pending navigation timer.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('First-ever open (onboarding not seen, not signed in) shows Onboarding', (tester) async {
    Get.put<AuthService>(FakeAuthService());
    Get.put<OnboardingService>(FakeOnboardingService()..seen = false);

    await pumpSplash(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Put a tag on\nyour car'), findsOneWidget);
  });

  testWidgets('Returning, signed-out resident (onboarding already seen) goes to Login', (tester) async {
    Get.put<AuthService>(FakeAuthService());
    Get.put<OnboardingService>(FakeOnboardingService()..seen = true);

    await pumpSplash(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Signed-in resident skips Onboarding/Login and lands on Dashboard', (tester) async {
    final fakeAuth = FakeAuthService();
    await fakeAuth.confirmOtp(verificationId: 'v', smsCode: '123456');
    Get.put<AuthService>(fakeAuth);
    // Onboarding not seen — signed-in status should still win.
    Get.put<OnboardingService>(FakeOnboardingService()..seen = false);

    await pumpSplash(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Your vehicles'), findsOneWidget);
  });
}
