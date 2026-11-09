import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLanguageNotifier = AppLanguageNotifier();

class AppLanguageNotifier extends ValueNotifier<Locale> {
  final Locale defaultLocale = const Locale('en', 'US');
  AppLanguageNotifier() : super(const Locale('en', 'US')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode =
        prefs.getString('language_code') ?? defaultLocale.languageCode;
    final countryCode =
        prefs.getString('countryCode') ?? defaultLocale.countryCode;
    value = Locale(languageCode, countryCode);
  }

  Future<void> changeLanguage(Locale locale) async {
    if (value == locale) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await prefs.setString('countryCode', locale.countryCode ?? '');
    value = locale;
  }
}
