import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parktag_app/app/services/auth_service.dart';
import 'package:parktag_app/app/utils/auth_input.dart';

String _apply(List<TextInputFormatter> formatters, String input) {
  var value = TextEditingValue(text: input, selection: TextSelection.collapsed(offset: input.length));
  for (final f in formatters) {
    value = f.formatEditUpdate(TextEditingValue.empty, value);
  }
  return value.text;
}

void main() {
  test('name rejects digits and caps length', () {
    expect(_apply(nameInputFormatters, "Ayesha Khan2"), 'Ayesha Khan');
    expect(_apply(nameInputFormatters, "O'Brien-Smith Jr."), "O'Brien-Smith Jr.");
    expect(_apply(nameInputFormatters, 'a' * 60).length, 50);
  });

  test('CNIC inserts hyphens at positions 6 and 14 and caps at 13 digits', () {
    expect(_apply(cnicInputFormatters, '42101'), '42101');
    expect(_apply(cnicInputFormatters, '421011'), '42101-1');
    expect(_apply(cnicInputFormatters, '4210112345671'), '42101-1234567-1');
    expect(_apply(cnicInputFormatters, '42101123456719999'), '42101-1234567-1');
  });

  test('Firebase error code 39 gets a readable message', () {
    final e = FirebaseAuthException(code: 'internal-error', message: 'An internal error has occurred. [ Error code:39 ]');
    expect(describeAuthFailure(e), contains('too many recent attempts'));
  });
}
