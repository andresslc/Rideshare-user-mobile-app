import '../../../../core/services/places_search_service.dart';

enum RideLocationType { pickup, dropoff }

class LocationEntity {
  final ResolvedPlace? resolvedPlace;
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final RideLocationType type;
  final DateTime timestamp;

  const LocationEntity({
    this.resolvedPlace,
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.timestamp,
  });

  LocationEntity copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    RideLocationType? type,
    DateTime? timestamp,
  }) {
    return LocationEntity(
      resolvedPlace: resolvedPlace,
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
