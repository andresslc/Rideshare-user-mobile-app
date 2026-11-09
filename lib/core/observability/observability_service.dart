import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ride_app/core/config/app_config.dart';
import 'package:ride_app/core/services/storage_service.dart';

import 'observability_sanitizer.dart';

class ObservabilityService {
  final FirebaseCrashlytics _crashlytics;
  final StorageService _storageService;
  final AppConfig _config;

  bool _initialized = false;
  String _appVersion = '', _buildNumber = '';

  ObservabilityService(this._crashlytics, this._storageService, this._config);

  Future<void> initialize() async {
    if (_initialized) return;

    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = packageInfo.version;
    _buildNumber = packageInfo.buildNumber;
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    await setCustomKeys(<String, Object?>{
      'app': 'user',
      'app_name': _config.appName,
      'app_version': packageInfo.version,
      'base_url': ObservabilitySanitizer.sanitizePath(_config.baseUrl),
      'build_number': packageInfo.buildNumber,
      'flavor': _config.flavor.name,
      'platform': defaultTargetPlatform.name,
    });
    await syncUserFromStorage();
    _initialized = true;
  }

  Future<void> syncUserFromStorage() async {
    await setUserId(_readStoredUserId());
  }

  Future<void> setUserId(String? userId) async {
    final String normalized = userId?.trim() ?? '';
    await _crashlytics.setUserIdentifier(normalized);
    await _crashlytics.setCustomKey(
      'user_id',
      normalized.isEmpty ? '<anonymous>' : normalized,
    );
  }

  Future<void> clearUser() async {
    await setUserId(null);
  }

  Future<void> setCustomKeys(Map<String, Object?> keys) async {
    for (final entry in keys.entries) {
      final Object value = _normalizeCustomKeyValue(entry.value);
      await _crashlytics.setCustomKey(entry.key, value);
    }
  }

  /// Address-search breadcrumbs contain counters and outcome categories only.
  /// Crashlytics retains these with reports; it does not aggregate all sessions.
  Future<void> recordAddressSearchEvent(Map<String, Object> event) async {
    if (!_initialized) return;
    const allowed = {
      'event',
      'application',
      'platform',
      'interaction',
      'field',
      'strategy',
      'method',
      'status',
      'elapsed_ms',
      'count',
      'reason',
      'category',
    };
    final safe = Map<String, Object>.fromEntries(
      event.entries.where((entry) => allowed.contains(entry.key)),
    );
    try {
      await _crashlytics.log(
        jsonEncode({
          'kind': 'address_search',
          'app_version': _appVersion,
          'build_number': _buildNumber,
          ...safe,
        }),
      );
    } catch (_) {
      /* Reporting cannot interrupt address entry. */
    }
  }

  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterFatalError(details);
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, Object?>? context,
    bool fatal = false,
  }) async {
    final Map<String, Object?> sanitizedContext = <String, Object?>{
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      ...?_sanitizeContext(context),
    };

    if (sanitizedContext.isNotEmpty) {
      await setCustomKeys(sanitizedContext);
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
      information: sanitizedContext.entries
          .map<DiagnosticsNode>(
            (entry) => StringProperty(entry.key, entry.value?.toString()),
          )
          .toList(growable: false),
    );
  }

  Future<void> recordApiFailure({
    required String method,
    required String path,
    int? statusCode,
    String? message,
    String? errorCode,
    Map<String, dynamic>? headers,
    dynamic requestBody,
    dynamic responseBody,
  }) async {
    final Map<String, Object?> context = <String, Object?>{
      'api_method': method.toUpperCase(),
      'api_path': ObservabilitySanitizer.sanitizePath(path),
    };
    if (statusCode != null) {
      context['api_status_code'] = statusCode;
    }
    if (message != null) {
      context['api_message'] = ObservabilitySanitizer.sanitizeMessage(message);
    }
    if (errorCode != null) {
      context['api_error_code'] = ObservabilitySanitizer.sanitizeMessage(
        errorCode,
      );
    }
    if (headers != null && headers.isNotEmpty) {
      context['api_headers'] = jsonEncode(
        ObservabilitySanitizer.sanitizeHeaders(headers),
      );
    }
    if (requestBody != null) {
      context['api_request_body'] = jsonEncode(
        ObservabilitySanitizer.sanitizeBody(requestBody),
      );
    }
    if (responseBody != null) {
      context['api_response_body'] = jsonEncode(
        ObservabilitySanitizer.sanitizeBody(responseBody),
      );
    }

    await recordNonFatal(
      StateError(
        'API failure: ${method.toUpperCase()} ${ObservabilitySanitizer.sanitizePath(path)}',
      ),
      StackTrace.current,
      reason: 'api_failure',
      context: context,
    );
  }

  Future<void> recordBusinessAnomaly({
    required String name,
    Map<String, Object?>? context,
  }) async {
    await recordNonFatal(
      StateError('Business anomaly: $name'),
      StackTrace.current,
      reason: 'business_anomaly',
      context: <String, Object?>{'anomaly_name': name, ...?context},
    );
  }

  Map<String, Object?>? _sanitizeContext(Map<String, Object?>? context) {
    if (context == null || context.isEmpty) {
      return null;
    }
    return context.map((key, value) {
      return MapEntry(
        key,
        _normalizeCustomKeyValue(
          key == 'api_headers'
              ? value
              : ObservabilitySanitizer.sanitizeBody(value),
        ),
      );
    });
  }

  Object _normalizeCustomKeyValue(Object? value) {
    if (value == null) return '<null>';
    if (value is bool || value is num || value is String) {
      return value is String
          ? ObservabilitySanitizer.sanitizeMessage(value) ?? '<empty>'
          : value;
    }
    return ObservabilitySanitizer.sanitizeMessage(value.toString()) ??
        '<empty>';
  }

  String? _readStoredUserId() {
    final String? storedUid = _storageService.getUID;
    if (storedUid != null && storedUid.trim().isNotEmpty) {
      return storedUid.trim();
    }

    final String? rawUser = _storageService.getUser;
    if (rawUser == null || rawUser.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(rawUser);
      if (decoded is Map && decoded['_id'] != null) {
        final String id = decoded['_id'].toString().trim();
        return id.isEmpty ? null : id;
      }
    } catch (_) {}

    return null;
  }
}
