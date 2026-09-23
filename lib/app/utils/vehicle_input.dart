import 'package:flutter/services.dart';

/// Characters allowed in a vehicle's identifying numbers.
///
/// "No special characters" deliberately still permits the hyphen and the
/// space: real plate, engine and chassis numbers contain them, and the
/// app's own placeholders are `LEA-2231`, `2ZR-4498231` and
/// `MR053CE3204119876`. Blocking the hyphen would reject the very examples
/// the form suggests. Everything else — punctuation, symbols, emoji — is
/// rejected as it is typed, including from a paste.
final vehicleIdentifierFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[A-Za-z0-9\- ]'),
);

/// Characters allowed in the vehicle's name-like fields — make, model,
/// address, nickname.
///
/// No hyphen here, unlike [vehicleIdentifierFormatter]: letters and digits
/// only, plus spaces. Digits stay allowed because blocking them would make
/// an address unable to hold a house number ("123 Model Town") and a model
/// unable to hold e.g. "Corolla 2.0" — only the hyphen and other symbols
/// are rejected, as typed or pasted.
final vehicleNameFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[A-Za-z0-9 ]'),
);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// How a registration date is written into the form and stored.
String formatRegistrationDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

/// Best-effort read of whatever is already in the date field, so opening
/// the picker starts on the date the vehicle already has.
///
/// Registration dates were free text before the picker existed, and they
/// arrive from OCR too, so several shapes are in the wild: `14 Mar 2022`,
/// `2021-04-02`, `14/03/2022`, `14-03-2022`. Anything unparseable returns
/// null and the picker simply opens on today.
DateTime? parseRegistrationDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  // ISO first: yyyy-mm-dd is unambiguous.
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
  if (iso != null) {
    return _build(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
  }

  // `14 Mar 2022` / `14-Mar-2022`.
  final named = RegExp(
    r'^(\d{1,2})[\s\-/.]+([A-Za-z]{3,9})[\s\-/.]+(\d{2,4})$',
  ).firstMatch(text);
  if (named != null) {
    final monthName = named.group(2)!.toLowerCase().substring(0, 3);
    final month = _months.indexWhere((m) => m.toLowerCase() == monthName) + 1;
    if (month > 0) {
      return _build(_year(named.group(3)!), month, int.parse(named.group(1)!));
    }
  }

  // `14/03/2022` — day first, matching how these dates are printed locally.
  final numeric = RegExp(r'^(\d{1,2})[\s\-/.]+(\d{1,2})[\s\-/.]+(\d{2,4})$').firstMatch(text);
  if (numeric != null) {
    return _build(_year(numeric.group(3)!), int.parse(numeric.group(2)!), int.parse(numeric.group(1)!));
  }

  return null;
}

int _year(String raw) {
  final value = int.parse(raw);
  if (raw.length > 2) return value;
  // Two-digit years: registration dates are in the past, so treat them as
  // 20xx rather than 19xx.
  return 2000 + value;
}

/// Rejects impossible dates (31 Feb) by checking the DateTime round-trips,
/// and anything in the future, which a registration date can never be.
DateTime? _build(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) return null;
  final now = DateTime.now();
  if (date.isAfter(DateTime(now.year, now.month, now.day))) return null;
  return date;
}
