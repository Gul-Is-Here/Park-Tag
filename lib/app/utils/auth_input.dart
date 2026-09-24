import 'package:flutter/services.dart';

/// Names: letters, spaces, and the few punctuation marks real names use
/// ("O'Brien", "Abdul-Rehman", "Muhammad A. Khan") — no digits.
final nameInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'\-]")),
  LengthLimitingTextInputFormatter(50),
];

/// CNIC: 13 digits, shown as 12345-1234567-1 (hyphens typed in for the
/// resident at positions 6 and 14).
final cnicInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(13),
  CnicInputFormatter(),
];

class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
