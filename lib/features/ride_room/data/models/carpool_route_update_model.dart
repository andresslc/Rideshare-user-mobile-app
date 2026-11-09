import 'package:ride_app/features/ride_room/domain/entities/carpool_route_update_entity.dart';

class CarpoolRouteUpdateModel extends CarpoolRouteUpdateEntity {
  const CarpoolRouteUpdateModel({
    required super.carpoolId,
    required super.status,
  });

  factory CarpoolRouteUpdateModel.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : json);

    return CarpoolRouteUpdateModel(
      carpoolId: payload['carpoolId']?.toString() ?? payload['carpoolld']?.toString() ?? '',
      status: payload['status']?.toString() ?? '',
    );
  }
}
