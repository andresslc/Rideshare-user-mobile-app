import 'package:ride_app/features/ride_room/domain/entities/ride_entity.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';

class RideResponseEntity {
  final String? type;
  final String? message;
  final RideEntity? ride;
  final String? rideOtp;
  final String? rideId;

  /// Only present on the `ride:request:create` ack: the result of the first
  /// dispatch ring, which runs inline with the request.
  final RideSearchStatusEntity? searchStatus;

  const RideResponseEntity({
    this.type,
    this.message,
    required this.ride,
    this.rideOtp,
    this.rideId,
    this.searchStatus,
  });

  RideResponseEntity copyWith({
    String? type,
    String? message,
    RideEntity? ride,
    String? rideOtp,
    String? rideId,
    RideSearchStatusEntity? searchStatus,
  }) {
    return RideResponseEntity(
      type: type ?? this.type,
      message: message ?? this.message,
      ride: ride ?? this.ride,
      rideOtp: rideOtp ?? this.rideOtp,
      rideId: rideId ?? this.rideId,
      searchStatus: searchStatus ?? this.searchStatus,
    );
  }
}
