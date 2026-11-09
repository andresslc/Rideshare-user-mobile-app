class ObservabilitySanitizer {
  static const int _maxValueLength = 500;
  static const Set<String> _sensitiveHeaderKeys = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'token',
    'x-api-key',
  };

  static const Set<String> _sensitiveBodyKeys = <String>{
    'address',
    'authorization',
    'cardnumber',
    'cvv',
    'email',
    'fcm',
    'fcmtoken',
    'password',
    'phone',
    'refreshtoken',
    'token',
  };

  static Map<String, Object?> sanitizeHeaders(Map<String, dynamic> headers) {
    final Map<String, Object?> sanitized = <String, Object?>{};
    headers.forEach((key, value) {
      final normalizedKey = key.toLowerCase();
      if (_sensitiveHeaderKeys.contains(normalizedKey)) {
        sanitized[key] = '<redacted>';
      } else {
        sanitized[key] = _sanitizeValue(value);
      }
    });
    return sanitized;
  }

  static Object? sanitizeBody(dynamic data) {
    return _sanitizeValue(data);
  }

  static String sanitizePath(String path) {
    final String trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '<unknown>';
    }
    final int queryIndex = trimmed.indexOf('?');
    return queryIndex >= 0 ? trimmed.substring(0, queryIndex) : trimmed;
  }

  static String? sanitizeMessage(String? message) {
    final String? trimmed = message?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return _truncate(trimmed);
  }

  static Object? _sanitizeValue(dynamic value, {String? key}) {
    if (value == null) return null;

    if (key != null && _sensitiveBodyKeys.contains(key.toLowerCase())) {
      return '<redacted>';
    }

    if (value is Map) {
      final Map<String, Object?> sanitized = <String, Object?>{};
      value.forEach((dynamic mapKey, dynamic mapValue) {
        final String keyString = mapKey.toString();
        sanitized[keyString] = _sanitizeValue(mapValue, key: keyString);
      });
      return sanitized;
    }

    if (value is List) {
      return value
          .take(20)
          .map<Object?>((dynamic item) => _sanitizeValue(item))
          .toList(growable: false);
    }

    if (value is String) {
      return _truncate(value);
    }

    if (value is num || value is bool) {
      return value;
    }

    return _truncate(value.toString());
  }

  static String _truncate(String value) {
    if (value.length <= _maxValueLength) {
      return value;
    }
    return '${value.substring(0, _maxValueLength)}…';
  }
}
