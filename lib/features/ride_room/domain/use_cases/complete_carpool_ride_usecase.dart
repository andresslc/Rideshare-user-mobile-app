import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/complete_carpool_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/complete_carpool_ride_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CompleteCarpoolRideUseCase {
  final RideSocketRepository repository;

  CompleteCarpoolRideUseCase(this.repository);

  Future<Either<Failure, CompleteCarpoolRideEntity>> call(
    CompleteCarpoolRideParams params,
  ) async {
    return repository.completeCarpoolRide(params);
  }
}
