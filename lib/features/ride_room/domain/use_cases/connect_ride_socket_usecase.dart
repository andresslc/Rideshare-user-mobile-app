import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';

import '../repositories/ride_socket_repository.dart';

class ConnectRideSocketUseCase {
  final RideSocketRepository repository;

  ConnectRideSocketUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.connect();
  }
}

