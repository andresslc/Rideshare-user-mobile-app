import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_passenger_picked_up_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolPassengerPickedUpUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolPassengerPickedUpUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolPassengerPickedUpEntity>> call() {
    return repository.carpoolPassengerPickedUpUpdates();
  }
}

