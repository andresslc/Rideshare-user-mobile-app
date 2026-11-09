import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../entities/share_ride_entity.dart';
import '../repositories/ride_socket_repository.dart';

class GetShareCarpoolRideUrlUseCase {
  final RideSocketRepository repository;

  GetShareCarpoolRideUrlUseCase(this.repository);

  Future<Either<Failure, ShareRideEntity>> call(String rideId) {
    return repository.getShareCarpoolRideUrl(rideId);
  }
}

