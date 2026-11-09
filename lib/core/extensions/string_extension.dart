/// Common string utilities.
extension StringExtension on String {
  /// Capitalise the first letter.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title case every word.
  String get titleCase => split(' ').map((w) => w.capitalised).join(' ');

  /// Check if string is a valid email (basic regex).
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Return null if empty, otherwise the string itself.
  String? get nullIfEmpty => isEmpty ? null : this;

  /// Formats phone number as +1 (123) 123-1234
  String get formatAsPhone {
    final digitsOnly = replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) {
      final main = digitsOnly.substring(digitsOnly.length - 10);
      return '+1 (${main.substring(0, 3)}) ${main.substring(3, 6)}-${main.substring(6)}';
    }
    return this;
  }

  /// Masks the phone number while keeping the last 4 digits visible.
  /// Example: `**** **** 0000`
  String formatAsMaskedPhone() {
    final digitsOnly = replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 4) return this;

    final last4 = digitsOnly.substring(digitsOnly.length - 4);
    return '**** **** $last4';
  }
}

extension USNumberFormatter on String {
  String toUSPhoneFormat({bool formatWithCode = false}) {
    // Remove everything except digits
    final digits = replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return '';

    // Keep last 10 digits (US number)
    final cleaned = digits.length > 10
        ? digits.substring(digits.length - 10)
        : digits;

    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i == 0) {
        if (formatWithCode) buffer.write('+1 ');
        buffer.write('(');
      }

      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');

      buffer.write(cleaned[i]);
    }

    return buffer.toString();
  }
}
