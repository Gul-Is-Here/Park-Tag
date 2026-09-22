/// Best-effort field extraction from an RC (Registration Certificate) card's
/// OCR text (FR-02.1). Pakistani RC cards aren't a single standardized
/// layout, so this works off two passes rather than a fixed template:
///   1. Line-by-line "label: value" / "label value" matching against known
///      field keywords.
///   2. A couple of format-specific regexes (plate number, chassis number)
///      run over the whole text as a fallback when no label was found.
///
/// This is heuristic, not exact — the Review screen it feeds is editable
/// specifically so a resident can fix whatever it gets wrong or misses.
class RcCardFields {
  const RcCardFields({
    this.make,
    this.model,
    this.plateNumber,
    this.color,
    this.dateOfRegistration,
    this.engineNumber,
    this.chassisNumber,
    this.address,
  });

  final String? make;
  final String? model;
  final String? plateNumber;
  final String? color;
  final String? dateOfRegistration;
  final String? engineNumber;
  final String? chassisNumber;
  final String? address;
}

/// Pakistani plate format: 2-3 letters, optional dash/space, 2-4 digits
/// (e.g. "LEA-2231", "ABC 123", "LEB4470").
final _platePattern = RegExp(r'\b[A-Z]{2,3}[\s-]?\d{2,4}\b');

/// Chassis numbers are long alphanumeric strings (commonly 11-17 chars),
/// distinct enough from plate numbers to pick out on their own when no
/// label precedes them.
final _chassisPattern = RegExp(r'\b[A-Z0-9]{11,17}\b');

final _datePattern = RegExp(
  r'\b\d{1,2}[\/\-. ](?:\d{1,2}|[A-Za-z]{3,9})[\/\-. ]\d{2,4}\b',
);

const _labelKeywords = <String, List<String>>{
  'make': ['make', 'manufacturer'],
  'model': ['model'],
  'plateNumber': ['regn no', 'reg no', 'reg. no', 'registration no', 'plate no', 'regn number'],
  'color': ['colour', 'color'],
  'dateOfRegistration': ['date of reg', 'regn date', 'reg date', 'registration date'],
  'engineNumber': ['engine no', 'engine number'],
  'chassisNumber': ['chassis no', 'chassis number'],
  'address': ['address'],
};

RcCardFields parseRcCardText(String recognizedText) {
  final lines = recognizedText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final values = <String, String>{};

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lower = line.toLowerCase();

    for (final entry in _labelKeywords.entries) {
      if (values.containsKey(entry.key)) continue;
      for (final keyword in entry.value) {
        if (!lower.contains(keyword)) continue;

        // "Label: Value" or "Label - Value" on the same line.
        final separatorIndex = line.indexOf(RegExp(r'[:\-]'));
        final sameLine = separatorIndex != -1 && separatorIndex + 1 < line.length
            ? line.substring(separatorIndex + 1).trim()
            : '';

        if (sameLine.isNotEmpty && sameLine.toLowerCase() != keyword) {
          values[entry.key] = sameLine;
        } else if (i + 1 < lines.length) {
          // Some RC layouts print the label and value on consecutive lines.
          values[entry.key] = lines[i + 1];
        }
        break;
      }
    }
  }

  // Fallbacks: scan the whole text for format-shaped values the label pass
  // might have missed (OCR often garbles short label words like "No").
  if (!values.containsKey('plateNumber')) {
    final match = _platePattern.firstMatch(recognizedText);
    if (match != null) values['plateNumber'] = match.group(0)!;
  }
  if (!values.containsKey('chassisNumber')) {
    final match = _chassisPattern.firstMatch(recognizedText);
    if (match != null) values['chassisNumber'] = match.group(0)!;
  }
  if (!values.containsKey('dateOfRegistration')) {
    final match = _datePattern.firstMatch(recognizedText);
    if (match != null) values['dateOfRegistration'] = match.group(0)!;
  }

  return RcCardFields(
    make: values['make'],
    model: values['model'],
    plateNumber: values['plateNumber'],
    color: values['color'],
    dateOfRegistration: values['dateOfRegistration'],
    engineNumber: values['engineNumber'],
    chassisNumber: values['chassisNumber'],
    address: values['address'],
  );
}
