import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';

/// Best-effort field extraction from an RC card's front/back photos.
/// Every field is nullable — the caller decides what "couldn't read
/// anything" means and every field stays editable on the Review screen
/// regardless.
class RcCardFields {
  const RcCardFields({
    this.make,
    this.makerName,
    this.plateNumber,
    this.color,
    this.dateOfRegistration,
    this.engineNumber,
    this.chassisNumber,
    this.address,
    this.mrzLine1,
    this.mrzLine2,
    this.mrzLine3,
  });

  factory RcCardFields.fromMap(Map<dynamic, dynamic> map) {
    String? read(String key) {
      final value = map[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return RcCardFields(
      make: read('make'),
      makerName: read('makerName'),
      plateNumber: read('plateNumber'),
      color: read('color'),
      dateOfRegistration: read('dateOfRegistration'),
      engineNumber: read('engineNumber'),
      chassisNumber: read('chassisNumber'),
      address: read('address'),
      mrzLine1: read('mrzLine1'),
      mrzLine2: read('mrzLine2'),
      mrzLine3: read('mrzLine3'),
    );
  }

  /// Value printed under the card's "Make" label — the vehicle model
  /// (e.g. "US 70"). Fills the form's "Make" field.
  final String? make;

  /// Value printed under the card's "Maker Name" label — the manufacturer
  /// (e.g. "UNITED"). Fills the form's "Maker Name" field.
  final String? makerName;
  final String? plateNumber;
  final String? color;
  final String? dateOfRegistration;
  final String? engineNumber;
  final String? chassisNumber;
  final String? address;

  /// The three machine-readable lines at the bottom of the card's back,
  /// used only to cross-check the fields above (see card_validator.dart).
  final String? mrzLine1;
  final String? mrzLine2;
  final String? mrzLine3;

  RcCardFields copyWith({
    String? make,
    String? makerName,
    String? plateNumber,
  }) => RcCardFields(
    make: make ?? this.make,
    makerName: makerName ?? this.makerName,
    plateNumber: plateNumber ?? this.plateNumber,
    color: color,
    dateOfRegistration: dateOfRegistration,
    engineNumber: engineNumber,
    chassisNumber: chassisNumber,
    address: address,
    mrzLine1: mrzLine1,
    mrzLine2: mrzLine2,
    mrzLine3: mrzLine3,
  );

  /// True when essentially nothing useful came back — drives the "couldn't
  /// read much from that photo" hint on the Review screen.
  bool get isMostlyEmpty =>
      make == null && plateNumber == null && chassisNumber == null;
}

/// Wraps the RC card front/back photo -> structured field extraction so
/// [ReviewVehicleController] never talks to Cloud Functions directly —
/// same pattern as the other services, and lets tests fake this out
/// instead of making a real network call.
abstract class RcOcrService {
  /// Reads whichever of [frontImagePath]/[backImagePath] are given and
  /// returns best-effort extracted fields, merged from both sides.
  Future<RcCardFields> extractFields({
    String? frontImagePath,
    String? backImagePath,
  });
}

/// Sends the card photos to the `extractRcCardFields` Cloud Function, which
/// forwards them to OpenAI's GPT-4o vision model server-side — the OpenAI
/// API key lives only in Cloud Functions secret storage, never in the app
/// itself (an API key shipped inside a mobile app binary can always be
/// extracted from it).
class OpenAiRcOcrService implements RcOcrService {
  final _functions = FirebaseFunctions.instance;

  @override
  Future<RcCardFields> extractFields({
    String? frontImagePath,
    String? backImagePath,
  }) async {
    final payload = <String, dynamic>{};
    if (frontImagePath != null) {
      payload['frontImageBase64'] = base64Encode(
        await File(frontImagePath).readAsBytes(),
      );
    }
    if (backImagePath != null) {
      payload['backImageBase64'] = base64Encode(
        await File(backImagePath).readAsBytes(),
      );
    }
    if (payload.isEmpty) {
      return const RcCardFields();
    }

    final callable = _functions.httpsCallable(
      'extractRcCardFields',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
    );
    final result = await callable.call(payload);
    return RcCardFields.fromMap(Map<dynamic, dynamic>.from(result.data as Map));
  }
}
