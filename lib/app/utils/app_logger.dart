import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Console logging for debugging. Every line is prefixed with `[Tag]` so it
/// can be filtered in the `flutter run` / Debug Console output (e.g. search
/// "[PhoneAuth]" or "ERROR"). Silent in release builds.
abstract final class AppLogger {
  static void debug(String tag, String message) {
    if (kReleaseMode) return;
    debugPrint('[$tag] $message');
  }

  /// Logs a caught error. Firebase errors get their `code`/`message` (and a
  /// Cloud Function's `details`) printed, since `toString()` alone often
  /// hides the useful part.
  static void error(String tag, Object error, [StackTrace? stack]) {
    if (kReleaseMode) return;
    final buffer = StringBuffer('[$tag] ERROR: ${error.runtimeType}');
    if (error is FirebaseException) {
      buffer
        ..write('\n  code: ${error.code}')
        ..write('\n  message: ${error.message}')
        ..write('\n  plugin: ${error.plugin}');
      if (error is FirebaseFunctionsException && error.details != null) {
        buffer.write('\n  details: ${error.details}');
      }
    } else {
      buffer.write('\n  $error');
    }
    if (stack != null) buffer.write('\n$stack');
    debugPrint(buffer.toString());
  }
}
