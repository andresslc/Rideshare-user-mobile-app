import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_booking_status_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolBookingStatusUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolBookingStatusUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolBookingStatusEntity>> call() {
    return repository.carpoolBookingStatusUpdates();
  }
}

