import 'package:parktag_app/app/services/rc_ocr_service.dart';

/// Canned extraction result shaped like a real RC card read, tuned so
/// existing tests see the same values the old hardcoded mock did — keeps
/// tests meaningful without ever making a real network call to the
/// `extractRcCardFields` Cloud Function / OpenAI.
const fakeRcCardFields = RcCardFields(
  make: 'Corolla Altis',
  makerName: 'Toyota',
  plateNumber: 'LEA-2231',
  color: 'White',
  dateOfRegistration: '14 Mar 2022',
  engineNumber: '2ZR-4498231',
  chassisNumber: 'MR053CE3204119876',
  address: '123-B, Model Town, Lahore',
);

class FakeRcOcrService implements RcOcrService {
  /// Set to override what the next [extractFields] call returns — e.g. to
  /// simulate an unreadable card. Defaults to [fakeRcCardFields].
  RcCardFields fieldsToReturn = fakeRcCardFields;

  int callCount = 0;

  @override
  Future<RcCardFields> extractFields({String? frontImagePath, String? backImagePath}) async {
    callCount++;
    return fieldsToReturn;
  }
}
