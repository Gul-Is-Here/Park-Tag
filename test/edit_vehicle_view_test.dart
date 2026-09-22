import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/vehicle_service.dart';
import 'package:parktag_app/modules/dashboard/controllers/home_tab_controller.dart';
import 'package:parktag_app/modules/dashboard/models/vehicle_model.dart';
import 'package:parktag_app/modules/vehicle_details/controllers/edit_vehicle_controller.dart';
import 'package:parktag_app/modules/vehicle_details/views/edit_vehicle_view.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_vehicle_service.dart';

const _vehicle = VehicleModel(
  nickname: 'White Corolla',
  makeModel: 'Toyota Corolla Altis',
  plateNumber: 'LEA-2231',
  color: Color(0xFFF5F1E8),
  colorName: 'White',
  dateOfRegistration: '14 Mar 2022',
  engineNumber: '2ZR-4498231',
  chassisNumber: 'MR053CE3204119876',
  address: '123-B, Model Town, Lahore',
  photoPaths: ['/tmp/front.jpg', '/tmp/back.jpg'],
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  setUp(() {
    Get.reset();
    Get.put<AuthService>(FakeAuthService());
    Get.put<VehicleService>(FakeVehicleService());
  });

  testWidgets('Edit screen pre-fills fields from the saved vehicle', (tester) async {
    final controller = Get.put(EditVehicleController(vehicle: _vehicle));

    expect(controller.make.text, 'Toyota');
    expect(controller.model.text, 'Corolla Altis');
    expect(controller.plateNumber.text, 'LEA-2231');
    expect(controller.nickname.text, 'White Corolla');
    expect(controller.vehiclePhotos, ['/tmp/front.jpg', '/tmp/back.jpg']);
    expect(controller.canSave, isTrue);
  });

  testWidgets('Removing a photo blocks save until 2 photos are present again', (tester) async {
    final controller = Get.put(EditVehicleController(vehicle: _vehicle));

    controller.removeVehiclePhoto(0);
    expect(controller.canSave, isFalse);

    controller.vehiclePhotos.add('/tmp/new-front.jpg');
    expect(controller.canSave, isTrue);
  });

  testWidgets('Edit screen renders the form and photo section', (tester) async {
    Get.put(EditVehicleController(vehicle: _vehicle));

    await tester.pumpWidget(const GetMaterialApp(home: EditVehicleView()));
    await tester.pump();

    expect(find.text('Edit Vehicle'), findsOneWidget);
    expect(find.text('2 of 2 added'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('Saving updates the vehicle in the Home tab list in place', (tester) async {
    Get.put(HomeTabController());
    final home = Get.find<HomeTabController>();
    home.vehicles.assignAll([_vehicle]);

    final controller = Get.put(EditVehicleController(vehicle: _vehicle));
    controller.nickname.text = 'Renamed Corolla';

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/start',
        getPages: [
          GetPage(name: '/start', page: () => const SizedBox()),
          GetPage(name: '/vehicle-details', page: () => const SizedBox()),
        ],
      ),
    );
    await tester.pump();

    controller.save();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(home.vehicles.length, 1);
    expect(home.vehicles.first.nickname, 'Renamed Corolla');
    expect(home.vehicles.first.plateNumber, 'LEA-2231');
  });
}
