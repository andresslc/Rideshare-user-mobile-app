import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../entities/share_ride_entity.dart';
import '../repositories/ride_socket_repository.dart';

class GetShareRideUrlUseCase {
  final RideSocketRepository repository;

  GetShareRideUrlUseCase(this.repository);

  Future<Either<Failure, ShareRideEntity>> call(String rideId) {
    return repository.getShareRideUrl(rideId);
  }
}

