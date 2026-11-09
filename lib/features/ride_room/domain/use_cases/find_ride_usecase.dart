import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/find_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class FindRideUseCase {
  final RideSocketRepository repository;

  FindRideUseCase(this.repository);

  Future<Either<Failure, RideResponseEntity>> call(
    FindRideParams params,
  ) async {
    return repository.findRide(params);
  }
}

