import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:parktag_app/modules/dashboard/controllers/home_tab_controller.dart';
import 'package:parktag_app/modules/vehicle/controllers/review_vehicle_controller.dart';
import 'package:parktag_app/modules/vehicle/views/review_vehicle_view.dart';

import 'support/fake_auth_service.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  setUp(Get.reset);

  testWidgets('Scan handoff pre-fills fields with the mock OCR result', (tester) async {
    final controller = Get.put(ReviewVehicleController(rcCardPath: '/tmp/rc.jpg'));

    expect(controller.make.text, 'Toyota');
    expect(controller.model.text, 'Corolla Altis');
    expect(controller.plateNumber.text, 'LEA-2231');
  });

  testWidgets('Manual entry starts with empty fields', (tester) async {
    final controller = Get.put(ReviewVehicleController(rcCardPath: null));

    expect(controller.make.text, isEmpty);
    expect(controller.plateNumber.text, isEmpty);
  });

  testWidgets('Save is blocked until 2 vehicle photos are added', (tester) async {
    final controller = Get.put(ReviewVehicleController(rcCardPath: '/tmp/rc.jpg'));

    expect(controller.canSave, isFalse);

    controller.vehiclePhotos.add(XFile('/tmp/one.jpg'));
    expect(controller.canSave, isFalse);

    controller.vehiclePhotos.add(XFile('/tmp/two.jpg'));
    expect(controller.canSave, isTrue);
  });

  testWidgets('Saving a vehicle adds it to the Home tab vehicle list', (tester) async {
    Get.put<AuthService>(FakeAuthService());
    DashboardBinding().dependencies();
    final home = Get.find<HomeTabController>();
    final startingCount = home.vehicles.length;

    final controller = Get.put(ReviewVehicleController(rcCardPath: '/tmp/rc.jpg'));
    controller.vehiclePhotos.addAll([XFile('/tmp/one.jpg'), XFile('/tmp/two.jpg')]);
    controller.nickname.text = 'Test Car';

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

    controller.save();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(home.vehicles.length, startingCount + 1);
    expect(home.vehicles.last.nickname, 'Test Car');
    expect(home.vehicles.last.plateNumber, 'LEA-2231');
  });

  testWidgets('Review screen renders form fields and the photo section', (tester) async {
    Get.put(ReviewVehicleController(rcCardPath: null));

    await tester.pumpWidget(const GetMaterialApp(home: ReviewVehicleView()));
    await tester.pump();

    expect(find.text('Review vehicle details'), findsOneWidget);
    expect(find.text('VEHICLE PHOTOS'), findsOneWidget);
    expect(find.text('0 of 2 added'), findsOneWidget);
    expect(find.text('Add 2 vehicle photos to continue'), findsOneWidget);
  });
}
