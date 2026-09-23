import 'package:flutter_test/flutter_test.dart';
import 'package:parktag_app/app/services/rc_ocr_service.dart';
import 'package:parktag_app/modules/vehicle/utils/card_validator.dart';

// Values from a real Punjab smart card (back side).
const _mrz1 = 'C<ETD<<<<<<<<<<<ANJ<5947<<<<<<<';
const _mrz2 = '<<<<<<<<071022<PAK<<<<<<<<<<<<<<';
const _mrz3 = 'US701353933<<<<<<<<<<<<<<<<<<<<<';

RcCardFields _card({
  String? make = 'US 70',
  String? makerName = 'UNITED',
  String? plate = 'ANJ 5947',
  String? chassis = 'US701353933',
  String? mrz1 = _mrz1,
  String? mrz3 = _mrz3,
}) => RcCardFields(
  make: make,
  makerName: makerName,
  plateNumber: plate,
  chassisNumber: chassis,
  mrzLine1: mrz1,
  mrzLine2: _mrz2,
  mrzLine3: mrz3,
);

void main() {
  group('helpers', () {
    test('looksLikeManufacturer', () {
      expect(looksLikeManufacturer('UNITED'), isTrue);
      expect(looksLikeManufacturer('Road Prince'), isTrue);
      expect(looksLikeManufacturer('ATLAS HONDA'), isTrue);
      expect(looksLikeManufacturer('US 70'), isFalse);
      expect(looksLikeManufacturer('CG 125'), isFalse);
      expect(looksLikeManufacturer('COROLLA GLI'), isFalse);
      expect(looksLikeManufacturer(null), isFalse);
    });

    test('MRZ parsing', () {
      expect(plateFromMrz(_mrz1), 'ANJ 5947');
      expect(chassisFromMrz(_mrz3), 'US701353933');
      expect(plateFromMrz('<<<<'), isNull);
      expect(chassisFromMrz('<<<<'), isNull);
    });
  });

  test('correct input passes through with high confidence', () {
    final r = validateCard(_card());
    expect(r.swapped, isFalse);
    expect(r.fields.make, 'US 70');
    expect(r.fields.makerName, 'UNITED');
    expect(r.flaggedFields, isEmpty);
    expect(r.confidenceOf(CardField.make), FieldConfidence.high);
    expect(r.confidenceOf(CardField.plateNumber), FieldConfidence.high);
  });

  test('swapped make/maker name is swapped back and flagged', () {
    final r = validateCard(_card(make: 'UNITED', makerName: 'US 70'));
    expect(r.swapped, isTrue);
    expect(r.fields.make, 'US 70');
    expect(r.fields.makerName, 'UNITED');
    expect(r.confidenceOf(CardField.make), FieldConfidence.low);
    expect(r.confidenceOf(CardField.makerName), FieldConfidence.low);
  });

  test('car cards are not false-flagged by the chassis prefix check', () {
    final r = validateCard(
      _card(
        make: 'COROLLA GLI',
        makerName: 'TOYOTA',
        chassis: 'NZE1701234',
        mrz3: 'NZE1701234<<<<',
      ),
    );
    expect(r.swapped, isFalse);
    expect(r.flaggedFields, isEmpty);
  });

  group('MRZ mismatch', () {
    test('make that does not prefix the chassis is low confidence', () {
      final r = validateCard(_card(make: 'CD 70'));
      expect(r.confidenceOf(CardField.make), FieldConfidence.low);
      expect(r.confidenceOf(CardField.makerName), FieldConfidence.high);
    });

    test('plate that disagrees with MRZ line 1 is low confidence', () {
      final r = validateCard(_card(plate: 'ANJ 5974'));
      expect(r.confidenceOf(CardField.plateNumber), FieldConfidence.low);
      expect(r.fields.plateNumber, 'ANJ 5974');
    });

    test('plate formatting differences are not a mismatch', () {
      expect(
        validateCard(
          _card(plate: 'ANJ-5947'),
        ).confidenceOf(CardField.plateNumber),
        FieldConfidence.high,
      );
    });

    test('chassis that disagrees with MRZ line 3 is low confidence', () {
      final r = validateCard(_card(chassis: 'US7O1353933'));
      expect(r.confidenceOf(CardField.chassisNumber), FieldConfidence.low);
    });
  });

  group('missing fields', () {
    test('missing make/maker name are reported as missing', () {
      final r = validateCard(_card(make: null, makerName: null));
      expect(r.confidenceOf(CardField.make), FieldConfidence.missing);
      expect(r.confidenceOf(CardField.makerName), FieldConfidence.missing);
      expect(r.swapped, isFalse);
    });

    test('missing plate/chassis are filled from the MRZ but flagged', () {
      final r = validateCard(_card(plate: null, chassis: null));
      expect(r.fields.plateNumber, 'ANJ 5947');
      expect(r.fields.chassisNumber, 'US701353933');
      expect(
        r.flaggedFields,
        containsAll([CardField.plateNumber, CardField.chassisNumber]),
      );
    });

    test('no MRZ at all skips the cross-checks', () {
      final r = validateCard(_card(mrz1: null, mrz3: null, make: 'CD 70'));
      expect(r.flaggedFields, isEmpty);
    });
  });
}
