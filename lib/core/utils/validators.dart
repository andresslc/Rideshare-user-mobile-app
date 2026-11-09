import 'package:flutter/services.dart';
import 'package:ride_app/core/core.dart';

class Validators {
  static final navigatorKey = rootNavigatorKey;

  static String? Function(String?) get requiredFieldValidator => (value) {
    if ((value?.trim() ?? '').isEmpty) {
      return navigatorKey.currentContext?.l10n.field_required;
    }
    return null;
  };

  static String? Function(String?) get fullNameValidator => (value) {
    final trimmedValue = value?.trim() ?? '';

    // final requiredError = requiredFieldValidator(trimmedValue);
    // if (requiredError != null) return requiredError;

    if (trimmedValue.length < 3) {
      return navigatorKey.currentContext?.l10n.name_min_length(
        3,
      ); // assumes you have l10n with param
    }

    if (RegExp(r'\d').hasMatch(trimmedValue)) {
      return navigatorKey.currentContext?.l10n.name_no_numbers;
    }

    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(trimmedValue)) {
      return navigatorKey.currentContext?.l10n.name_invalid_characters;
    }

    return null;
  };

  static String? Function(String?) get validateUSPhoneNumber => (value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return navigatorKey.currentContext?.l10n.field_required;
    }

    final digits = trimmedValue.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return navigatorKey.currentContext?.l10n.phone_invalid;
    }

    return null;
  };

  static String? Function(String?) get emailValidator => (value) {
    final trimmedValue = value?.trim() ?? '';

    const pattern =
        r'^(?!.*\.\.)(?!.*\.-)(?!.*-\.)' // no consecutive dots or dot-hyphen/hyphen-dot
        r'[a-zA-Z0-9](?:[a-zA-Z0-9._%+-]{0,63}[a-zA-Z0-9])?' // local part
        r'@'
        r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?' // domain
        r'(?:\.[a-zA-Z]{2,})+$'; // TLD

    final regex = RegExp(pattern);

    if (trimmedValue.isEmpty) {
      return navigatorKey.currentContext?.l10n.field_required;
    }

    if (trimmedValue.length > 254) {
      return navigatorKey.currentContext?.l10n.email_too_long;
    }

    if (!regex.hasMatch(trimmedValue)) {
      return navigatorKey.currentContext?.l10n.invalid_email;
    }

    return null;
  };

  static String? Function(String?) get amountValidator => (value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return navigatorKey.currentContext?.l10n.field_required;
    }

    final amount = double.tryParse(trimmedValue);

    if (amount == null) {
      return navigatorKey.currentContext?.l10n.valid_amount;
    }

    if (amount <= 0) {
      return navigatorKey.currentContext?.l10n.amount_must_be_greater_than_0;
    }

    // check max 2 decimal places
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmedValue)) {
      return navigatorKey.currentContext?.l10n.max_2_decimal_places_allowed;
    }

    return null;
  };

  //DOB
  static String? Function(String?) get dobValidator => (value) {
    final l10n = navigatorKey.currentContext?.l10n;
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return l10n?.field_required;
    }

    DateTime? dob;

    try {
      // ISO format: 2001-04-23
      if (trimmedValue.contains('-')) {
        dob = DateTime.parse(trimmedValue);
      }
      // US format: 4/23/2001
      else if (trimmedValue.contains('/')) {
        final parts = trimmedValue.split('/');

        if (parts.length != 3) {
          return l10n?.invalid_date_format ?? 'Invalid date format';
        }

        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        dob = DateTime(year, month, day);
      } else {
        return l10n?.invalid_date_format;
      }

      final today = DateTime.now();
      // if (dob.isAfter(today)) {
      //   return l10n?.invalid_date_format;
      // }
      int age = today.year - dob.year;

      final hasHadBirthdayThisYear =
          (today.month > dob.month) ||
          (today.month == dob.month && today.day >= dob.day);

      if (!hasHadBirthdayThisYear) {
        age--;
      }

      if (age < 15) {
        return l10n?.min_age_15_required;
      }
    } catch (e) {
      return l10n?.invalid_date_format;
    }

    return null;
  };
  //Address
  static String? Function(String?) get addressValidator => (value) {
    final l10n = navigatorKey.currentContext?.l10n;
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return l10n?.field_required;
    }

    if (text.length < 5) {
      return l10n?.minimum_5_characters_required;
    }

    // 123456
    if (RegExp(r'^\d+$').hasMatch(text)) {
      return l10n?.address_cannot_be_only_numbers;
    }

    // @#$%^&*
    if (RegExp(r"^[^A-Za-z0-9]+$", unicode: true).hasMatch(text)) {
      return l10n?.address_invalid;
    }

    return null;
  };

  static String? Function(String?) get stateValidator => (value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return navigatorKey.currentContext?.l10n.field_required ??
          'Field is required';
    }

    final normalized = text.toLowerCase();
    final isFlorida = normalized == 'florida' || normalized == 'fl';
    // normalized.contains;
    // ('florida') ||
    // RegExp(r'\bfl\b').hasMatch(normalized);

    if (!isFlorida) {
      return navigatorKey
              .currentContext
              ?.l10n
              .only_florida_addresses_supported ??
          'Only Florida (FL) addresses are supported';
    }

    return null;
  };
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
