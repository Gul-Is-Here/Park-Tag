import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/services/rc_ocr_service.dart';
import 'package:parktag_app/app/services/vehicle_service.dart';
import 'package:parktag_app/app/utils/vehicle_input.dart';
import 'package:parktag_app/modules/vehicle/controllers/review_vehicle_controller.dart';
import 'package:parktag_app/modules/vehicle/views/review_vehicle_view.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_rc_ocr_service.dart';
import 'support/fake_vehicle_service.dart';

/// Add Vehicle's Review screen shares [vehicleIdentifierFormatter] with
/// Edit Vehicle — the formatter itself is unit-tested in
/// edit_vehicle_view_test.dart. This file only pins that the three
/// identifier fields on THIS screen actually have it wired in, since that
/// wiring is exactly what regressed here before.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.reset();
    final fakeAuth = FakeAuthService();
    fakeAuth.signInAs(uid: 'resident-1', phone: '+923001234567');
    Get.put<AuthService>(fakeAuth);
    Get.put<VehicleService>(FakeVehicleService());
    Get.put<RcOcrService>(FakeRcOcrService());
  });

  Future<TextField> fieldWithHint(WidgetTester tester, String hint) async {
    return tester.widget<TextField>(
      find.ancestor(of: find.text(hint), matching: find.byType(TextField)).first,
    );
  }

  testWidgets('Registration, engine and chassis number fields reject special characters', (
    tester,
  ) async {
    Get.put(ReviewVehicleController(frontImagePath: null, backImagePath: null));

    await tester.pumpWidget(const GetMaterialApp(home: ReviewVehicleView()));
    await tester.pump();

    for (final hint in ['LEA-2231', '2ZR-4498231', 'MR053CE3204119876']) {
      final field = await fieldWithHint(tester, hint);
      expect(
        field.inputFormatters,
        contains(vehicleIdentifierFormatter),
        reason: '"$hint" field must filter special characters',
      );
    }
  });

  testWidgets('Make, model and address fields filter special characters', (tester) async {
    Get.put(ReviewVehicleController(frontImagePath: null, backImagePath: null));

    await tester.pumpWidget(const GetMaterialApp(home: ReviewVehicleView()));
    await tester.pump();

    for (final hint in [
      'US 70',
      'UNITED',
      '123 B Model Town Lahore',
    ]) {
      final field = await fieldWithHint(tester, hint);
      expect(
        field.inputFormatters,
        contains(vehicleNameFormatter),
        reason: '"$hint" field must filter non-alphanumeric special characters',
      );
    }
  });
}
