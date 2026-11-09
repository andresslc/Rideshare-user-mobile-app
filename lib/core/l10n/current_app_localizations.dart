import 'package:flutter/material.dart';
import 'package:ride_app/l10n/app_localizations.dart';
import 'package:ride_app/l10n/language_change_notifier.dart';

/// Resolves [AppLocalizations] using the same locale as [MaterialApp.router].
///
/// Use from notifiers / services that do not have a [BuildContext].
AppLocalizations currentAppLocalizations() {
  final String code = appLanguageNotifier.value.languageCode;
  final Locale locale =
      code == 'es' ? const Locale('es') : const Locale('en');
  return lookupAppLocalizations(locale);
}
