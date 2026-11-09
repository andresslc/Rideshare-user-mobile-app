import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_completed_entity.dart';

class CarpoolRideCompletedModel extends CarpoolRideCompletedEntity {
  const CarpoolRideCompletedModel({
    required super.bookingId,
    required super.carpoolId,
    required super.fareCharged,
    required super.rideCompletedAt,
  });

  factory CarpoolRideCompletedModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : json);

    return CarpoolRideCompletedModel(
      bookingId: payload['bookingId']?.toString() ?? '',
      carpoolId: payload['carpoolId']?.toString() ?? '',
      fareCharged: (payload['fareCharged'] as num?)?.toDouble() ?? 0.0,
      rideCompletedAt: DateTime.tryParse(
        payload['rideCompletedAt']?.toString() ?? '',
      ),
    );
  }
}
