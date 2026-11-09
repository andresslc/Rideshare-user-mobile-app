import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/find_carpool_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';

abstract class CarpoolRideRepository {
  Future<Either<Failure, CarpoolRideEntity>> getCarpoolRideById(String rideId);

  Future<Either<Failure, CarpoolRideResponseEntity>> findCarpoolRidesByAPI(
    FindCarpoolRideParams params,
  );
}
