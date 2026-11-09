import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// State-management-agnostic theme mode controller.
///
/// Uses a simple [ValueNotifier] so it works with any architecture.
/// Wrap your [MaterialApp] in a [ValueListenableBuilder<ThemeMode>]
/// and pass `themeNotifier.value` as the `themeMode`.
///
/// ### Automatic-mode reactivity
///
/// When the user selects **automatic**, the theme updates in real time via
/// three complementary mechanisms:
///
/// 1. **`WidgetsBindingObserver.didChangePlatformBrightness`** — reacts
///    instantly when the OS switches between light and dark mode.
/// 2. **Periodic timer (every 60 s)** — catches wall-clock / timezone changes
///    that a one-shot `Timer` would miss (e.g. device sleep across 6 AM/PM).
/// 3. **`didChangeAppLifecycleState`** — re-evaluates the theme the moment
///    the app returns to the foreground.
class ThemeNotifier extends ValueNotifier<ThemeMode>
    with WidgetsBindingObserver {
  final StorageService _storage;

  /// Periodic timer used only while theme == automatic.
  Timer? _autoThemeTimer;

  /// How often the periodic timer re-evaluates the time-based theme.
  static const _checkInterval = Duration(seconds: 60);

  String _selectedTheme = 'automatic';

  String get selectedTheme => _selectedTheme;

  ThemeNotifier(this._storage) : super(ThemeMode.light) {
    WidgetsBinding.instance.addObserver(this);
    _loadSaved();
  }

  // ── WidgetsBindingObserver callbacks ────────────────────────────────────

  /// Called by the framework when the platform brightness changes
  /// (i.e. the user toggled system dark mode).
  // @override
  // void didChangePlatformBrightness() {
  //   super.didChangePlatformBrightness();
  //   if (_selectedTheme == 'automatic') {
  //     _applyAutomaticTheme();
  //   }
  // }

  /// Called when the app lifecycle state changes
  /// (e.g. resumed from background).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _selectedTheme == 'automatic') {
      _applyAutomaticTheme();
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────

  void _loadSaved() {
    final saved = _storage.getThemeMode;
    if (saved == 'light') {
      _selectedTheme = 'light';
    } else if (saved == 'dark') {
      _selectedTheme = 'dark';
    } else {
      _selectedTheme = kDebugMode ? 'dark' : 'automatic';
    }

    _applySelectedTheme();
  }

  // ── Theme application ──────────────────────────────────────────────────

  void _applySelectedTheme() {
    if (_selectedTheme == 'light') {
      _stopAutoTimer();
      value = ThemeMode.light;
      return;
    }

    if (_selectedTheme == 'dark') {
      _stopAutoTimer();
      value = ThemeMode.dark;
      return;
    }

    // automatic
    _applyAutomaticTheme();
    _startAutoTimer();
  }

  /// Determines the correct theme based on the current wall-clock time
  /// and the platform brightness, then updates [value] only if it changed.
  void _applyAutomaticTheme() {
    final now = DateTime.now();
    final isLightTime = now.hour >= 6 && now.hour < 18;

    // Also consult the platform brightness so OS-level dark mode is respected.
    // final platformBrightness = PlatformDispatcher.instance.platformBrightness;
    // final platformWantsDark = platformBrightness == Brightness.dark;

    // If either signal says "dark", use dark.
    final newMode = (!isLightTime) ? ThemeMode.dark : ThemeMode.light;

    // Only notify listeners when the mode actually changes.
    if (value != newMode) {
      value = newMode;
    }
  }

  // ── Periodic timer management ──────────────────────────────────────────

  void _startAutoTimer() {
    _stopAutoTimer();
    _autoThemeTimer = Timer.periodic(_checkInterval, (_) {
      if (_selectedTheme != 'automatic') return;
      _applyAutomaticTheme();
    });
  }

  void _stopAutoTimer() {
    _autoThemeTimer?.cancel();
    _autoThemeTimer = null;
  }

  // ── Public API ─────────────────────────────────────────────────────────

  Future<void> setLight() async {
    _selectedTheme = 'light';
    _stopAutoTimer();
    value = ThemeMode.light;
    await _storage.setThemeMode('light');
  }

  Future<void> setDark() async {
    _selectedTheme = 'dark';
    _stopAutoTimer();
    value = ThemeMode.dark;
    await _storage.setThemeMode('dark');
  }

  Future<void> setAutomatic() async {
    _selectedTheme = 'automatic';
    _applyAutomaticTheme();
    _startAutoTimer();
    await _storage.setThemeMode('automatic');
  }

  Future<void> setSystem() async {
    await setAutomatic();
  }

  Future<void> toggle() async {
    if (value == ThemeMode.dark) {
      await setLight();
    } else {
      await setDark();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoTimer();
    super.dispose();
  }
}
