import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_completed_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolRideCompletedUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolRideCompletedUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolRideCompletedEntity>> call() {
    return repository.carpoolRideCompletedUpdates();
  }
}

