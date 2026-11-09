import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_started_entity.dart';

class CarpoolRideStartedModel extends CarpoolRideStartedEntity {
  const CarpoolRideStartedModel({
    required super.carpoolId,
    required super.status,
    required super.message,
  });

  factory CarpoolRideStartedModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : json);

    return CarpoolRideStartedModel(
      carpoolId: payload['carpoolId']?.toString() ?? '',
      status: payload['status']?.toString() ?? '',
      message: payload['message']?.toString() ?? json['message']?.toString() ?? '',
    );
  }
}
