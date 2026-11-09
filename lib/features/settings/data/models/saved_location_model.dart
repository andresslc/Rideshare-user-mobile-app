import 'package:ride_app/features/settings/domain/entities/saved_location_entity.dart';

class SavedLocationModel extends SavedLocationEntity {
  const SavedLocationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.city,
    required super.state,
    required super.country,
    required super.lat,
    required super.lng,
    required super.order,
    required super.isDeleted,
    super.createdAt,
    super.updatedAt,
  });

  factory SavedLocationModel.fromJson(Map<String, dynamic> json) {
    final coordinatesMap = json['coordinates'] as Map<String, dynamic>?;
    final coordinates =
        (coordinatesMap?['coordinates'] as List<dynamic>? ?? <dynamic>[]);

    final double lng =
        coordinates.isNotEmpty ? (coordinates[0] as num?)?.toDouble() ?? 0.0 : 0.0;
    final double lat =
        coordinates.length > 1 ? (coordinates[1] as num?)?.toDouble() ?? 0.0 : 0.0;

    return SavedLocationModel( 
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      lat: lat,
      lng: lng,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
