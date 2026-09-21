import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/routes/app_pages.dart';
import 'package:parktag_app/app/routes/app_routes.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:parktag_app/modules/dashboard/views/dashboard_view.dart';

import 'support/fake_auth_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    Get.put<AuthService>(FakeAuthService());
  });

  testWidgets('Dashboard shows the Home tab with vehicle cards and a center scanner button', (
    tester,
  ) async {
    DashboardBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));
    await tester.pump();

    expect(find.text('White Corolla'), findsOneWidget);
    expect(find.text('Your vehicles'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Tapping Messages switches the visible tab to the Inbox', (tester) async {
    DashboardBinding().dependencies();

    await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));
    await tester.pump();

    await tester.tap(find.text('Messages'));
    await tester.pump();

    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Please move your car'), findsOneWidget);
    expect(find.text('Your vehicles'), findsNothing);
  });

  testWidgets('Tapping a thread opens the chat and back returns to the Inbox', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.dashboard,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Messages'));
    await tester.pump();

    await tester.tap(find.text('Please move your car'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Has this issue been resolved?'), findsOneWidget);
    expect(find.text('Please move your car'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets('Entering the full OTP and verifying lands on Dashboard', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.otp,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump();

    final digitFields = find.byType(TextField);
    for (var i = 0; i < 6; i++) {
      await tester.enterText(digitFields.at(i), '1');
    }
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Your vehicles'), findsOneWidget);
  });
}
