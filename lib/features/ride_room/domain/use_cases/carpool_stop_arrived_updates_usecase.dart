import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_stop_arrived_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolStopArrivedUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolStopArrivedUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolStopArrivedEntity>> call() {
    return repository.carpoolStopArrivedUpdates();
  }
}

