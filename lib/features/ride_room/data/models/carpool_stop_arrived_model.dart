import 'package:ride_app/features/ride_room/data/models/carpool_ride_response_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_stop_arrived_entity.dart';

Map<String, dynamic>? _asStopArrivedMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class CarpoolStopArrivedModel extends CarpoolStopArrivedEntity {
  const CarpoolStopArrivedModel({
    required super.carpoolId,
    super.arrivedStop,
    super.nextStop,
  });

  factory CarpoolStopArrivedModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : json);

    final Map<String, dynamic>? arrivedStop = _asStopArrivedMap(
      payload['arrivedStop'],
    );
    final Map<String, dynamic>? nextStop = _asStopArrivedMap(payload['nextStop']);

    return CarpoolStopArrivedModel(
      carpoolId: payload['carpoolId']?.toString() ?? '',
      arrivedStop: arrivedStop == null
          ? null
          : CarpoolRideStopModel.fromJson(arrivedStop),
      nextStop: nextStop == null ? null : CarpoolRideStopModel.fromJson(nextStop),
    );
  }
}
