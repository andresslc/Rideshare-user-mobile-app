import 'dart:convert';

import 'package:ride_app/features/ride_room/data/models/location_model.dart';

abstract class LocationLocalDataSource {
  Future<List<LocationModel>> getRecentLocations();

  Future<void> saveRecentLocation(LocationModel location, {int maxItems = 10});
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  static const String _recentsKey = 'ride_room_recent_locations';

  final Future<String?> Function(String key) _read;
  final Future<bool> Function(String key, String value) _write;

  LocationLocalDataSourceImpl({
    required Future<String?> Function(String key) read,
    required Future<bool> Function(String key, String value) write,
  }) : _read = read,
       _write = write;

  @override
  Future<List<LocationModel>> getRecentLocations() async {
    final raw = await _read(_recentsKey);
    if (raw == null || raw.isEmpty) return <LocationModel>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <LocationModel>[];

    final parsed = decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(LocationModel.fromJson)
        .toList();

    parsed.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return parsed;
  }

  @override
  Future<void> saveRecentLocation(
    LocationModel location, {
    int maxItems = 10,
  }) async {
    final items = await getRecentLocations();
    final dedupeKey = _dedupeKey(location);

    final merged = <LocationModel>[
      location,
      ...items.where((item) => _dedupeKey(item) != dedupeKey),
    ];

    final limited = merged.take(maxItems).toList();
    final payload = jsonEncode(limited.map((item) => item.toJson()).toList());
    await _write(_recentsKey, payload);
  }

  String _dedupeKey(LocationModel model) {
    final lat = model.latitude;
    final lng = model.longitude;
    if (lat == 0 && lng == 0) {
      return model.address.trim().toLowerCase();
    }
    return '${lat.toStringAsFixed(5)}|${lng.toStringAsFixed(5)}';
  }
}
