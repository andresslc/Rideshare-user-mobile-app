import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/cancel_carpool_request_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/joined_carpool_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CancelCarpoolRideRequestUseCase {
  final RideSocketRepository repository;

  CancelCarpoolRideRequestUseCase(this.repository);

  Future<Either<Failure, JoinedCarpoolEntity>> call(
    CancelCarpoolRequestParams params,
  ) async {
    return repository.cancelCarpoolRideRequest(params);
  }
}

