import 'package:ride_app/features/ride_room/domain/entities/complete_carpool_ride_entity.dart';

class CompleteCarpoolRideModel extends CompleteCarpoolRideEntity {
  const CompleteCarpoolRideModel({
    required super.bookingId,
    required super.carpoolCompleted,
    required super.rideCompletedAt,
    required super.message,
  });

  factory CompleteCarpoolRideModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});

    return CompleteCarpoolRideModel(
      bookingId: payload['bookingId']?.toString() ?? '',
      carpoolCompleted: payload['carpoolCompleted'] == true,
      rideCompletedAt: DateTime.tryParse(
        payload['rideCompletedAt']?.toString() ?? '',
      ),
      message: json['message']?.toString() ?? '',
    );
  }
}