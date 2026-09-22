import 'package:parktag_app/app/services/rc_ocr_service.dart';

/// Canned OCR text shaped like a real RC card, tuned so
/// `parseRcCardText` extracts the same values the old hardcoded mock did —
/// keeps existing tests meaningful without ever touching the real ML Kit
/// platform channel (unavailable in the widget test environment).
const fakeRcCardText = '''
Make: Toyota
Model: Corolla Altis
Regn No: LEA-2231
Colour: White
Date of Reg: 14 Mar 2022
Engine No: 2ZR-4498231
Chassis No: MR053CE3204119876
Address: 123-B, Model Town, Lahore
''';

class FakeRcOcrService implements RcOcrService {
  /// Set to override what the next [recognizeText] call returns — e.g. to
  /// simulate an unreadable card. Defaults to [fakeRcCardText].
  String textToReturn = fakeRcCardText;

  int callCount = 0;

  @override
  Future<String> recognizeText(String imagePath) async {
    callCount++;
    return textToReturn;
  }
}
