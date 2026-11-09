import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class RideSearchStatusUpdatesUseCase {
  final RideSocketRepository repository;

  RideSearchStatusUpdatesUseCase(this.repository);

  Stream<Either<Failure, RideSearchStatusEntity>> call() {
    return repository.rideSearchStatusUpdates();
  }
}
