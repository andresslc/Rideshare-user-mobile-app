import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_route_update_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolRouteUpdateUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolRouteUpdateUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolRouteUpdateEntity>> call() {
    return repository.carpoolRouteUpdateUpdates();
  }
}
