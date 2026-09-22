import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps on-device OCR for a captured RC card photo (FR-02.1) so
/// [ReviewVehicleController] never talks to the ML Kit platform channel
/// directly — same pattern as the other services, and lets tests fake this
/// out instead of hitting real (unavailable-in-tests) native code.
abstract class RcOcrService {
  /// Returns the raw recognized text from the photo at [imagePath]. Field
  /// extraction from that text lives in `parseRcCardText`, kept separate
  /// so it can be tested without any OCR/platform dependency at all.
  Future<String> recognizeText(String imagePath);
}

class MlKitRcOcrService implements RcOcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText(String imagePath) async {
    final result = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    return result.text;
  }
}
