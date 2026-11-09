import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';

class RideSearchStatusModel extends RideSearchStatusEntity {
  const RideSearchStatusModel({
    super.rideId,
    required super.ring,
    super.totalRings,
    required super.radiusMiles,
    required super.radius,
    super.distanceUnit,
    super.message,
    required super.driversNotified,
    required super.totalNotified,
    super.nextRingInSeconds,
  });

  factory RideSearchStatusModel.fromJson(Map<String, dynamic> json) {
    final double miles = _toDouble(json['radiusMiles']) ?? 0;
    final String? message = json['message']?.toString().trim();

    return RideSearchStatusModel(
      rideId: json['rideId']?.toString(),
      ring: _toInt(json['ring']) ?? 1,
      totalRings: _toInt(json['totalRings']),
      radiusMiles: miles,
      // Falling back to miles keeps an older backend readable rather than
      // printing a zero next to the unit.
      radius: _toDouble(json['radius']) ?? miles,
      distanceUnit: json['distanceUnit']?.toString() ?? 'mi',
      message: (message == null || message.isEmpty) ? null : message,
      driversNotified: _toInt(json['driversNotified']) ?? 0,
      totalNotified: _toInt(json['totalNotified']) ?? 0,
      nextRingInSeconds: _toInt(json['nextRingInSeconds']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rideId': rideId,
      'ring': ring,
      'totalRings': totalRings,
      'radiusMiles': radiusMiles,
      'radius': radius,
      'distanceUnit': distanceUnit,
      'message': message,
      'driversNotified': driversNotified,
      'totalNotified': totalNotified,
      'nextRingInSeconds': nextRingInSeconds,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
