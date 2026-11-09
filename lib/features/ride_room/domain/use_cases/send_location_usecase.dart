import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

import '../../../../core/params/current_location_params.dart';

class SendCurrentLocationUseCase {
  final RideSocketRepository repository;

  SendCurrentLocationUseCase(this.repository);

  Future<Either<Failure, void>> call({required CurrentLocationParams params}) {
    return repository.sendCurrentLocation(params: params);
  }
}
