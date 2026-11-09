import 'package:ride_app/features/ride_room/domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.type,
    required super.timestamp,
  });

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      type: entity.type,
      timestamp: entity.timestamp,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?) ?? RideLocationType.dropoff.name;
    final parsedType = rawType == RideLocationType.pickup.name
        ? RideLocationType.pickup
        : RideLocationType.dropoff;

    return LocationModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      latitude: ((json['latitude'] as num?) ?? 0).toDouble(),
      longitude: ((json['longitude'] as num?) ?? 0).toDouble(),
      type: parsedType,
      timestamp:
          DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
