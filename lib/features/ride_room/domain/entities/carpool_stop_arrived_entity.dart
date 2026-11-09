import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';

class CarpoolStopArrivedEntity {
  final String carpoolId;
  final CarpoolRideStopEntity? arrivedStop;
  final CarpoolRideStopEntity? nextStop;

  const CarpoolStopArrivedEntity({
    required this.carpoolId,
    this.arrivedStop,
    this.nextStop,
  });
}
