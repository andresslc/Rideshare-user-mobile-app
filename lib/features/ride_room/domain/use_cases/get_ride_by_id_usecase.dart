import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class GetRideByIdUseCase {
  final RideSocketRepository repository;

  GetRideByIdUseCase(this.repository);

  Future<Either<Failure, RideResponseEntity>> call(String rideId) {
    return repository.getRideById(rideId);
  }
}

