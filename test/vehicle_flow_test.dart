import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/conversation_service.dart';
import 'package:parktag_app/app/services/push_notification_service.dart';
import 'package:parktag_app/app/services/rc_ocr_service.dart';
import 'package:parktag_app/app/services/vehicle_service.dart';
import 'package:parktag_app/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:parktag_app/modules/dashboard/controllers/home_tab_controller.dart';
import 'package:parktag_app/modules/vehicle/controllers/review_vehicle_controller.dart';
import 'package:parktag_app/modules/vehicle/views/review_vehicle_view.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_conversation_service.dart';
import 'support/fake_push_notification_service.dart';
import 'support/fake_rc_ocr_service.dart';
import 'support/fake_vehicle_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  setUp(() {
    Get.reset();
    final fakeAuth = FakeAuthService();
    fakeAuth.signInAs(
      uid: 'resident-1',
      phone: '+923001234567',
      profile: {'name': 'Ayesha Khan', 'phone': '+923001234567'},
    );
    Get.put<AuthService>(fakeAuth);
    Get.put<VehicleService>(FakeVehicleService());
    Get.put<ConversationService>(FakeConversationService());
    Get.put<PushNotificationService>(FakePushNotificationService());
    Get.put<RcOcrService>(FakeRcOcrService());
  });

  testWidgets('Scan handoff pre-fills fields from the OCR result', (tester) async {
    final controller = Get.put(ReviewVehicleController(frontImagePath: '/tmp/rc.jpg', backImagePath: '/tmp/rc-back.jpg'));
    // OCR now runs asynchronously (a real on-device recognizer call in
    // production) — let that microtask resolve before asserting.
    await tester.pump();

    expect(controller.make.text, 'Corolla Altis');
    expect(controller.model.text, 'Toyota');
    expect(controller.plateNumber.text, 'LEA-2231');
  });

  testWidgets('Manual entry starts with empty fields', (tester) async {
    final controller = Get.put(ReviewVehicleController(frontImagePath: null, backImagePath: null));

    expect(controller.make.text, isEmpty);
    expect(controller.plateNumber.text, isEmpty);
  });

  testWidgets('Save is blocked until 2 vehicle photos are added', (tester) async {
    final controller = Get.put(ReviewVehicleController(frontImagePath: '/tmp/rc.jpg', backImagePath: '/tmp/rc-back.jpg'));
    await tester.pump();

    expect(controller.canSave, isFalse);

    controller.vehiclePhotos.add(XFile('/tmp/one.jpg'));
    expect(controller.canSave, isFalse);

    controller.vehiclePhotos.add(XFile('/tmp/two.jpg'));
    expect(controller.canSave, isTrue);
  });

  testWidgets('Saving a vehicle persists it via VehicleService and adds it to the Home tab', (tester) async {
    final fakeVehicles = Get.find<VehicleService>() as FakeVehicleService;
    DashboardBinding().dependencies();
    final home = Get.find<HomeTabController>();
    final startingCount = home.vehicles.length;

    final controller = Get.put(ReviewVehicleController(frontImagePath: '/tmp/rc.jpg', backImagePath: '/tmp/rc-back.jpg'));
    controller.vehiclePhotos.addAll([XFile('/tmp/one.jpg'), XFile('/tmp/two.jpg')]);
    // OCR runs on init (both paths are set above) and fills plateNumber
    // from the fake card text — let that resolve before saving.
    await tester.pump();

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/start',
        getPages: [
          GetPage(name: '/start', page: () => const SizedBox()),
          GetPage(name: '/dashboard', page: () => const SizedBox()),
        ],
      ),
    );
    await tester.pump();

    await controller.save();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(fakeVehicles.saved, hasLength(1));
    // No nickname field on Review anymore (aligned with Edit Vehicle) —
    // it falls back to the plate number, same as Edit's save() does.
    expect(fakeVehicles.saved.single['nickname'], 'LEA-2231');
    expect(fakeVehicles.saved.single['uid'], 'resident-1');

    expect(home.vehicles.length, startingCount + 1);
    expect(home.vehicles.last.nickname, 'LEA-2231');
    expect(home.vehicles.last.plateNumber, 'LEA-2231');
    expect(home.vehicles.last.id, fakeVehicles.saved.single['id']);
  });

  testWidgets('Review screen renders form fields and the photo section', (tester) async {
    Get.put(ReviewVehicleController(frontImagePath: null, backImagePath: null));

    await tester.pumpWidget(const GetMaterialApp(home: ReviewVehicleView()));
    await tester.pump();

    expect(find.text('Review vehicle details'), findsOneWidget);
    expect(find.text('VEHICLE PHOTOS'), findsOneWidget);
    expect(find.text('0 of 2 added'), findsOneWidget);
    expect(find.text('Add 2 vehicle photos to continue'), findsOneWidget);
  });
}
