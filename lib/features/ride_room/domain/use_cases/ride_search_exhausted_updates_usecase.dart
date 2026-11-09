import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_search_exhausted_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class RideSearchExhaustedUpdatesUseCase {
  final RideSocketRepository repository;

  RideSearchExhaustedUpdatesUseCase(this.repository);

  Stream<Either<Failure, RideSearchExhaustedEntity>> call() {
    return repository.rideSearchExhaustedUpdates();
  }
}
