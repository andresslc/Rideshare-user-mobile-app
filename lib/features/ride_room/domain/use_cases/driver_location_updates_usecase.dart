import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/driver_location_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class DriverLocationUpdatesUseCase {
  final RideSocketRepository repository;

  DriverLocationUpdatesUseCase(this.repository);

  Stream<Either<Failure, DriverLocationEntity>> call() {
    return repository.driverLocationUpdates();
  }
}

