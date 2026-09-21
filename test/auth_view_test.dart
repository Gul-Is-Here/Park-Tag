import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/routes/app_routes.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/modules/auth/bindings/auth_binding.dart';
import 'package:parktag_app/modules/auth/views/login_view.dart';
import 'package:parktag_app/modules/auth/views/signup_view.dart';

import 'support/fake_auth_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(Get.reset);

  testWidgets('Login screen renders phone field and switch link', (tester) async {
    Get.put<AuthService>(FakeAuthService());
    AuthBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: LoginView()));
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('+92'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('Sign up requires the required fields before sending OTP', (tester) async {
    Get.put<AuthService>(FakeAuthService());
    AuthBinding().dependencies();

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.signUp,
        getPages: [
          GetPage(name: AppRoutes.signUp, page: () => const SignUpView()),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Create your account'), findsOneWidget);

    await tester.ensureVisible(find.text('Send OTP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send OTP'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('A few things are missing'), findsOneWidget);

    // Let the snackbar's auto-dismiss timer finish so no timer is left
    // pending when the test tears down.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Login blocks an unregistered number and points to sign up', (tester) async {
    final fakeAuth = FakeAuthService()..registerAllByDefault = false;
    Get.put<AuthService>(fakeAuth);
    AuthBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: LoginView()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '3001234567');
    await tester.tap(find.text('Send OTP'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('No account found'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Registering a number lets it log in afterwards', (tester) async {
    final fakeAuth = FakeAuthService()..registerAllByDefault = false;
    Get.put<AuthService>(fakeAuth);
    AuthBinding().dependencies();

    // Sign up registers the phone (FakeAuthService.createResidentProfile).
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.signUp,
        getPages: [
          GetPage(name: AppRoutes.signUp, page: () => const SignUpView()),
          GetPage(name: AppRoutes.otp, page: () => const SizedBox.shrink()),
        ],
      ),
    );
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'e.g. Ayesha Khan'), 'Ayesha Khan');
    await tester.enterText(find.byType(TextField).at(1), '3001234567');
    await tester.enterText(find.widgetWithText(TextField, '42101-1234567-1'), '42101-1234567-1');
    await tester.ensureVisible(find.text('Send OTP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send OTP'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(fakeAuth.registeredPhones, isEmpty, reason: 'phone is only recorded once OTP is confirmed');

    // Simulate the OTP screen confirming and creating the profile directly
    // against the fake, mirroring what OtpController.verify() would do.
    final uid = await fakeAuth.confirmOtp(verificationId: 'fake-verification-id', smsCode: '123456');
    await fakeAuth.createResidentProfile(
      uid: uid,
      name: 'Ayesha Khan',
      phone: '+923001234567',
      cnic: '42101-1234567-1',
    );

    expect(fakeAuth.registeredPhones, contains('+923001234567'));
    expect(await fakeAuth.phoneIsRegistered('+923001234567'), isTrue);
    expect(fakeAuth.profiles[uid]?['cnic'], '42101-1234567-1');

    // The signup flow above navigated to the (stub) OTP route, which shows
    // no snackbar, but a real "Send OTP" tap does — flush any pending timer.
    await tester.pump(const Duration(seconds: 4));
  });
}
