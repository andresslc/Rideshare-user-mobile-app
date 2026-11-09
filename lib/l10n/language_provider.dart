import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'language_change_notifier.dart';

final languageProvider = ChangeNotifierProvider<AppLanguageNotifier>((ref) {
  return appLanguageNotifier;
});

final localeProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).value;
});
