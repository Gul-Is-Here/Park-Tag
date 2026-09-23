import '../../../app/services/rc_ocr_service.dart';

/// How far a scanned field can be trusted.
enum FieldConfidence {
  /// Read and consistent with the card's other data.
  high,

  /// Read, but something disagreed (auto-swapped, or MRZ mismatch) — the
  /// resident should double-check it.
  low,

  /// Not read at all.
  missing,
}

/// Field keys used in [CardValidationResult.confidence].
abstract final class CardField {
  static const make = 'make';
  static const makerName = 'makerName';
  static const plateNumber = 'plateNumber';
  static const chassisNumber = 'chassisNumber';
}

class CardValidationResult {
  const CardValidationResult({
    required this.fields,
    required this.confidence,
    required this.swapped,
  });

  /// The (possibly corrected) fields to pre-fill the form with.
  final RcCardFields fields;

  /// Per-field confidence, keyed by [CardField].
  final Map<String, FieldConfidence> confidence;

  /// True when make/maker name came back the wrong way round and were
  /// swapped back.
  final bool swapped;

  FieldConfidence confidenceOf(String field) =>
      confidence[field] ?? FieldConfidence.missing;

  /// Fields that were read but should be double-checked.
  List<String> get flaggedFields => confidence.entries
      .where((e) => e.value == FieldConfidence.low)
      .map((e) => e.key)
      .toList();
}

/// Manufacturers seen on Pakistani registration cards. Upper-case; matched
/// against the whole normalized value, so "ATLAS HONDA" still counts as
/// HONDA.
const knownManufacturers = <String>{
  'UNITED',
  'HONDA',
  'ATLAS HONDA',
  'SUZUKI',
  'PAK SUZUKI',
  'YAMAHA',
  'ROAD PRINCE',
  'SUPER POWER',
  'SUPER STAR',
  'QINGQI',
  'CHANGAN',
  'TOYOTA',
  'INDUS MOTOR',
  'DAIHATSU',
  'KIA',
  'HYUNDAI',
  'NISSAN',
  'MG',
  'HAVAL',
  'PROTON',
  'DFSK',
  'FAW',
  'BMW',
  'AUDI',
  'MERCEDES',
  'MITSUBISHI',
  'ISUZU',
  'HINO',
};

String _normalize(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
String _compact(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// A manufacturer name has no digits and contains a known brand as a
/// whole word.
bool looksLikeManufacturer(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  if (RegExp(r'\d').hasMatch(value)) return false;
  final padded = ' ${_normalize(value)} ';
  return knownManufacturers.any((brand) => padded.contains(' $brand '));
}

/// Registration number from MRZ line 1, e.g. "C<ETD<<<<ANJ<5947<<<" →
/// "ANJ 5947". Null when it can't be found.
String? plateFromMrz(String? line1) {
  if (line1 == null) return null;
  final match = RegExp(
    r'([A-Z]{1,4})<(\d{1,4})(?![0-9])',
  ).firstMatch(line1.toUpperCase().replaceAll(' ', ''));
  return match == null ? null : '${match.group(1)} ${match.group(2)}';
}

/// Chassis number from MRZ line 3 — everything before the first "<",
/// e.g. "US701353933<<<<" → "US701353933".
String? chassisFromMrz(String? line3) {
  if (line3 == null) return null;
  final head = line3.toUpperCase().replaceAll(' ', '').split('<').first;
  return head.isEmpty ? null : head;
}

/// Checks GPT's extraction against itself and the card's MRZ, fixing what
/// it safely can (a make/maker-name swap) and flagging the rest.
CardValidationResult validateCard(RcCardFields input) {
  var fields = input;
  final confidence = <String, FieldConfidence>{};
  var swapped = false;

  // 1. Make/maker-name swap: the maker is the brand; the make is the model.
  if (looksLikeManufacturer(fields.make) &&
      !looksLikeManufacturer(fields.makerName)) {
    fields = RcCardFields(
      make: fields.makerName,
      makerName: fields.make,
      plateNumber: fields.plateNumber,
      color: fields.color,
      dateOfRegistration: fields.dateOfRegistration,
      engineNumber: fields.engineNumber,
      chassisNumber: fields.chassisNumber,
      address: fields.address,
      mrzLine1: fields.mrzLine1,
      mrzLine2: fields.mrzLine2,
      mrzLine3: fields.mrzLine3,
    );
    swapped = true;
  }

  FieldConfidence base(String? v) =>
      v == null ? FieldConfidence.missing : FieldConfidence.high;
  confidence[CardField.make] = base(fields.make);
  confidence[CardField.makerName] = base(fields.makerName);
  confidence[CardField.plateNumber] = base(fields.plateNumber);
  confidence[CardField.chassisNumber] = base(fields.chassisNumber);

  if (swapped) {
    confidence[CardField.make] = FieldConfidence.low;
    confidence[CardField.makerName] = FieldConfidence.low;
  }
  if (fields.makerName != null && !looksLikeManufacturer(fields.makerName)) {
    confidence[CardField.makerName] = FieldConfidence.low;
  }

  // 2. MRZ line 3 starts with the chassis number.
  final mrzChassis = chassisFromMrz(fields.mrzLine3);
  if (mrzChassis != null) {
    if (fields.chassisNumber == null) {
      fields = RcCardFields(
        make: fields.make,
        makerName: fields.makerName,
        plateNumber: fields.plateNumber,
        color: fields.color,
        dateOfRegistration: fields.dateOfRegistration,
        engineNumber: fields.engineNumber,
        chassisNumber: mrzChassis,
        address: fields.address,
        mrzLine1: fields.mrzLine1,
        mrzLine2: fields.mrzLine2,
        mrzLine3: fields.mrzLine3,
      );
      confidence[CardField.chassisNumber] = FieldConfidence.low;
    } else if (_compact(fields.chassisNumber!) != mrzChassis) {
      confidence[CardField.chassisNumber] = FieldConfidence.low;
    }

    // Model codes like "US 70" / "CD 70" prefix the chassis ("US701353933").
    // Only checked for codes with digits — car model names ("COROLLA GLI")
    // never prefix the chassis, so checking them would always false-flag.
    final make = fields.make;
    if (make != null &&
        RegExp(r'\d').hasMatch(make) &&
        !mrzChassis.startsWith(_compact(make))) {
      confidence[CardField.make] = FieldConfidence.low;
    }
  }

  // 3. MRZ line 1 carries the registration number.
  final mrzPlate = plateFromMrz(fields.mrzLine1);
  if (mrzPlate != null) {
    if (fields.plateNumber == null) {
      fields = fields.copyWith(plateNumber: mrzPlate);
      confidence[CardField.plateNumber] = FieldConfidence.low;
    } else if (_compact(fields.plateNumber!) != _compact(mrzPlate)) {
      confidence[CardField.plateNumber] = FieldConfidence.low;
    }
  }

  return CardValidationResult(
    fields: fields,
    confidence: confidence,
    swapped: swapped,
  );
}
