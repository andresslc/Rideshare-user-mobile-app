import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class RideStatusUpdatesUseCase {
  final RideSocketRepository repository;

  RideStatusUpdatesUseCase(this.repository);

  Stream<Either<Failure, RideResponseEntity>> call() {
    return repository.rideStatusUpdates();
  }
}

