/// Parses API `dob` values (epoch ms, numeric string, or ISO-8601).
DateTime? parseDobFromJson(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
  }
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt, isUtc: true);
    }
    return DateTime.tryParse(trimmed);
  }
  return null;
}
