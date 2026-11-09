import 'package:ride_app/features/ride_room/domain/entities/driver_location_entity.dart';

class DriverLocationModel extends DriverLocationEntity {
  const DriverLocationModel({
    required super.driver,
    required super.coordinates,
    required super.timestamp,
    super.eta,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawCoordinates =
        json['coordinates'] as List<dynamic>? ?? <dynamic>[];

    return DriverLocationModel(
      driver: (json['driver'] ?? '').toString(),
      coordinates: rawCoordinates
          .map((item) => (item as num).toDouble())
          .toList(),
      timestamp: _toInt(json['timestamp']),
      eta: json['eta']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'driver': driver,
      'coordinates': coordinates,
      'timestamp': timestamp,
      if (eta != null) 'eta': eta,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
