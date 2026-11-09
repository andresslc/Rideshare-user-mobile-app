import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class RideResumeUpdatesUseCase {
  final RideSocketRepository repository;

  RideResumeUpdatesUseCase(this.repository);

  Stream<Either<Failure, RideResponseEntity>> call() {
    return repository.rideResumeUpdates();
  }
}

