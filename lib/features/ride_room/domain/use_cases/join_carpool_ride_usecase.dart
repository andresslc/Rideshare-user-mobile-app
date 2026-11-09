import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/find_carpool_ride_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/joined_carpool_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class JoinCarpoolRideUseCase {
  final RideSocketRepository repository;

  JoinCarpoolRideUseCase(this.repository);

  Future<Either<Failure, JoinedCarpoolEntity>> call(
    FindCarpoolRideParams params,
  ) async {
    return repository.joinCarpoolRide(params);
  }
}

