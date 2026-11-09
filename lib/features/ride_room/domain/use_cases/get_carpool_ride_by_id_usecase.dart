import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/carpool_ride_repository.dart';

class GetCarpoolRideByIdUseCase {
  final CarpoolRideRepository repository;

  GetCarpoolRideByIdUseCase(this.repository);

  Future<Either<Failure, CarpoolRideEntity>> call(String rideId) async {
    return repository.getCarpoolRideById(rideId);
  }
}

