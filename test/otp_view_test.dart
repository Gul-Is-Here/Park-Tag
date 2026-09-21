import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/routes/app_pages.dart';
import 'package:parktag_app/app/routes/app_routes.dart';
import 'package:parktag_app/app/services/auth_service.dart';

import 'support/fake_auth_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    Get.put<AuthService>(FakeAuthService());
  });

  testWidgets('Login sends OTP and navigates to the OTP screen with the phone number', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(initialRoute: AppRoutes.login, getPages: AppPages.routes),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).last, '3001234567');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your number'), findsOneWidget);
    expect(find.textContaining('+92 3001234567'), findsOneWidget);
  });

  testWidgets('OTP screen shows six digit boxes and a resend countdown', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.otp,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.textContaining('Resend code in 0:'), findsOneWidget);

    // Let the countdown timer run to completion so it self-cancels and
    // nothing is left pending when the test tears down.
    await tester.pump(const Duration(seconds: 61));
  });
}
