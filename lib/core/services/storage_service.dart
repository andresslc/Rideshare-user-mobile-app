import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Generic SharedPreferences wrapper for common persistence needs.
///
/// Add domain-specific keys/methods as your app grows —
/// but keep this class free of business logic.
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // ── Auth ────────────────────────────────────────────────────────────────

  static const String _keyToken = 'token';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUID = 'uid';
  static const String _keyUser = 'user';

  Future<void> setToken(String token) async =>
      _prefs.setString(_keyToken, token);

  String? get getToken => _prefs.getString(_keyToken);

  Future<void> setLoginStatus(bool loggedIn) async =>
      _prefs.setBool(_keyIsLoggedIn, loggedIn);

  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;

  Future<void> setUID(String uid) async => _prefs.setString(_keyUID, uid);

  String? get getUID => _prefs.getString(_keyUID);

  Future<bool> setUser(Map<String, dynamic>? val) async =>
      _prefs.setString(_keyUser, jsonEncode(val));

  String? get getUser => _prefs.getString(_keyUser);

  // ── Language ────────────────────────────────────────────────────────────

  static const String _keyLanguageCode = 'language_code';

  Future<void> setLanguageCode(String languageCode) async =>
      _prefs.setString(_keyLanguageCode, languageCode);

  String? get getLanguageCode => _prefs.getString(_keyLanguageCode);


  /// Clears only authentication/session related keys.
  Future<void> clearAuthSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyUID);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }
  // ── Theme ───────────────────────────────────────────────────────────────

  static const String _keyThemeMode = 'theme_mode';

  Future<void> setThemeMode(String mode) async =>
      _prefs.setString(_keyThemeMode, mode);

  String? get getThemeMode => _prefs.getString(_keyThemeMode);

  // ── FCM ─────────────────────────────────────────────────────────────────

  static const String _keyFCM = 'fcm_token';

  Future<void> setFCMToken(String token) async =>
      _prefs.setString(_keyFCM, token);

  String? get getFCMToken => _prefs.getString(_keyFCM);

  // ── Location ────────────────────────────────────────────────────────────

  static const String _keyLocationPermission = 'location_permission_granted';
  static const String _keyLocationPromptShown = 'location_prompt_shown';

  Future<void> setLocationPermissionGranted(bool granted) async =>
      _prefs.setBool(_keyLocationPermission, granted);

  bool get isLocationPermissionGranted =>
      _prefs.getBool(_keyLocationPermission) ?? false;

  Future<void> setLocationPromptShown(bool shown) async =>
      _prefs.setBool(_keyLocationPromptShown, shown);

  bool get hasSeenLocationPrompt =>
      _prefs.getBool(_keyLocationPromptShown) ?? false;

  // ── Generic helpers ─────────────────────────────────────────────────────

  Future<void> clear() async => _prefs.clear();

  Future<bool> remove(String key) async => _prefs.remove(key);

  // ── Ride chat sheet badge (unread driver message scope) ────────────────

  /// Opaque scope string, e.g. `normal:<rideId>` or `carpool:<bookingId>`.
  static const String _keyRideChatBadgeUnreadScope = 'ride_chat_badge_unread_scope';

  void setRideChatBadgeUnreadScope(String scope) {
    final String trimmed = scope.trim();
    if (trimmed.isEmpty) return;
    _prefs.setString(_keyRideChatBadgeUnreadScope, trimmed);
  }

  String? get getRideChatBadgeUnreadScope =>
      _prefs.getString(_keyRideChatBadgeUnreadScope);

  void clearRideChatBadgeUnreadScope() {
    _prefs.remove(_keyRideChatBadgeUnreadScope);
  }

  // ── Active ride ETA (persisted across app restarts) ────────────────────

  /// Stored as `"<rideId>|<eta>"` so a stale ETA from a previous ride
  /// is never accidentally restored for a different ride.
  static const String _keyActiveRideEta = 'active_ride_eta';

  /// Persists the last known-good ETA for [rideId].
  Future<void> setActiveRideEta(String rideId, String eta) async {
    final String trimmedId = rideId.trim();
    final String trimmedEta = eta.trim();
    if (trimmedId.isEmpty || trimmedEta.isEmpty) return;
    await _prefs.setString(_keyActiveRideEta, '$trimmedId|$trimmedEta');
  }

  /// Returns the persisted ETA for [rideId], or `null` if none / stale.
  String? getActiveRideEta(String rideId) {
    final String? raw = _prefs.getString(_keyActiveRideEta);
    if (raw == null) return null;
    final int sep = raw.indexOf('|');
    if (sep <= 0) return null;
    final String storedId = raw.substring(0, sep);
    if (storedId != rideId.trim()) return null; // belongs to a different ride
    final String storedEta = raw.substring(sep + 1);
    return storedEta.isEmpty ? null : storedEta;
  }

  /// Returns the raw persisted ETA string without ride ID check, used on startup.
  String? get getActiveRideEtaRaw {
    final String? raw = _prefs.getString(_keyActiveRideEta);
    if (raw == null) return null;
    final int sep = raw.indexOf('|');
    if (sep <= 0) return null;
    final String storedEta = raw.substring(sep + 1).trim();
    return storedEta.isEmpty ? null : storedEta;
  }

  /// Clears the persisted ETA (call on ride complete / cancel).
  Future<void> clearActiveRideEta() async {
    await _prefs.remove(_keyActiveRideEta);
  }
}
