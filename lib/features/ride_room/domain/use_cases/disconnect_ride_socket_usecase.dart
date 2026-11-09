import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class DisconnectRideSocketUseCase {
  final RideSocketRepository repository;

  DisconnectRideSocketUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.disconnect();
  }
}

