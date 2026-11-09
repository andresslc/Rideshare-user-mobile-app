import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/repositories/carpool_ride_repository.dart';

import '../../../../core/params/find_carpool_ride_params.dart';
import '../entities/carpool_ride_response_entity.dart';

class FindCarpoolRidesByApiUseCase {
  final CarpoolRideRepository repository;

  FindCarpoolRidesByApiUseCase(this.repository);

  Future<Either<Failure, CarpoolRideResponseEntity>> call(
    FindCarpoolRideParams params,
  ) async {
    return repository.findCarpoolRidesByAPI(params);
  }
}

