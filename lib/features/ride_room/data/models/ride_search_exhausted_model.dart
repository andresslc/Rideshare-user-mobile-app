import 'package:ride_app/features/ride_room/domain/entities/ride_search_exhausted_entity.dart';

class RideSearchExhaustedModel extends RideSearchExhaustedEntity {
  const RideSearchExhaustedModel({
    super.rideId,
    super.reason,
    super.message,
    super.radiusReachedMiles,
    super.radiusReached,
    super.distanceUnit,
  });

  factory RideSearchExhaustedModel.fromJson(Map<String, dynamic> json) {
    final double? miles = _toDouble(json['radiusReachedMiles']);

    return RideSearchExhaustedModel(
      rideId: json['rideId']?.toString(),
      reason: json['reason']?.toString(),
      message: json['message']?.toString(),
      radiusReachedMiles: miles,
      radiusReached: _toDouble(json['radiusReached']) ?? miles,
      distanceUnit: json['distanceUnit']?.toString() ?? 'mi',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rideId': rideId,
      'reason': reason,
      'message': message,
      'radiusReachedMiles': radiusReachedMiles,
      'radiusReached': radiusReached,
      'distanceUnit': distanceUnit,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
