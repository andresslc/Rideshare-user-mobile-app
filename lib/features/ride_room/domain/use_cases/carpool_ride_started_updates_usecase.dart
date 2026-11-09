import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_started_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolRideStartedUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolRideStartedUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolRideStartedEntity>> call() {
    return repository.carpoolRideStartedUpdates();
  }
}

