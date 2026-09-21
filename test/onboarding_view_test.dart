import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/routes/app_pages.dart';
import 'package:parktag_app/app/routes/app_routes.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/onboarding_service.dart';
import 'package:parktag_app/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:parktag_app/modules/onboarding/views/onboarding_view.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_onboarding_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  setUp(() {
    Get.reset();
    Get.put<AuthService>(FakeAuthService());
    Get.put<OnboardingService>(FakeOnboardingService());
  });

  testWidgets('Onboarding renders first step with dots and Next', (tester) async {
    Get.put(OnboardingController());

    await tester.pumpWidget(const GetMaterialApp(home: OnboardingView()));
    await tester.pump();

    expect(find.text('Put a tag on\nyour car'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Tapping Next advances through all steps to Get Started', (tester) async {
    Get.put(OnboardingController());

    await tester.pumpWidget(const GetMaterialApp(home: OnboardingView()));
    await tester.pump();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Get notified,\nnever exposed'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Chat, resolve,\nmove on'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Skip navigates straight to Login and marks onboarding as seen', (tester) async {
    final fakeOnboarding = Get.find<OnboardingService>() as FakeOnboardingService;

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.onboarding,
        getPages: AppPages.routes,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(fakeOnboarding.seen, isTrue);
  });
}
