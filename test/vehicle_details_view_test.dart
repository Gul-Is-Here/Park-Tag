import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/vehicle_service.dart';
import 'package:parktag_app/modules/dashboard/controllers/home_tab_controller.dart';
import 'package:parktag_app/modules/dashboard/models/vehicle_model.dart';
import 'package:parktag_app/modules/vehicle_details/controllers/vehicle_details_controller.dart';
import 'package:parktag_app/modules/vehicle_details/views/vehicle_details_view.dart';

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
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });

  setUp(() {
    Get.reset();
    final fakeAuth = FakeAuthService();
    fakeAuth.signInAs(uid: 'resident-1', phone: '+923001234567');
    Get.put<AuthService>(fakeAuth);
    Get.put<VehicleService>(FakeVehicleService());
  });

  testWidgets('Vehicle details screen renders the plate, QR card and info rows', (tester) async {
    Get.put(VehicleDetailsController(vehicle: _vehicle));

    await tester.pumpWidget(const GetMaterialApp(home: VehicleDetailsView()));
    await tester.pump();

    expect(find.text('White Corolla'), findsOneWidget);
    expect(find.text('LEA-2231'), findsOneWidget);
    expect(find.text('SCAN TO VERIFY VEHICLE'), findsOneWidget);
    expect(find.text('Edit Vehicle'), findsOneWidget);
    expect(find.text('Remove Vehicle'), findsOneWidget);
    expect(find.text('123-B, Model Town, Lahore'), findsOneWidget);
  });

  testWidgets(
    'Confirming the remove dialog deletes the vehicle from the backend and the Home tab list',
    (tester) async {
      final fakeVehicles = Get.find<VehicleService>() as FakeVehicleService;
      Get.put(HomeTabController());
      final home = Get.find<HomeTabController>();
      // HomeTabController subscribes to watchVehicles on init — let that
      // first (empty, since nothing was saved through the service here)
      // emission settle before seeding the list by hand, or it overwrites
      // this assignAll right back to empty.
      await tester.pump();
      home.vehicles.assignAll([_vehicle]);

      Get.put(VehicleDetailsController(vehicle: _vehicle));

      await tester.pumpWidget(const GetMaterialApp(home: VehicleDetailsView()));
      await tester.pump();

      await tester.ensureVisible(find.text('Remove Vehicle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove Vehicle'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      // The dialog itself awaits the delete before popping — pump past
      // that async gap rather than assuming it's instant.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));

      expect(fakeVehicles.deletedIds, contains(_vehicle.id));
      expect(home.vehicles.contains(_vehicle), isFalse);
    },
  );

  testWidgets('A failed delete keeps the dialog open with an error, and does not remove the vehicle', (
    tester,
  ) async {
    final fakeVehicles = Get.find<VehicleService>() as FakeVehicleService;
    fakeVehicles.throwOnDelete = true;

    Get.put(HomeTabController());
    final home = Get.find<HomeTabController>();
    await tester.pump();
    home.vehicles.assignAll([_vehicle]);

    Get.put(VehicleDetailsController(vehicle: _vehicle));

    await tester.pumpWidget(const GetMaterialApp(home: VehicleDetailsView()));
    await tester.pump();

    await tester.ensureVisible(find.text('Remove Vehicle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Vehicle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.pump();

    expect(find.text("Couldn't remove the vehicle. Please try again."), findsOneWidget);
    expect(home.vehicles.contains(_vehicle), isTrue);
  });
}
