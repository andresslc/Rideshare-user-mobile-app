import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class SocketErrorsUseCase {
  final RideSocketRepository repository;

  SocketErrorsUseCase(this.repository);

  Stream<Either<Failure, String>> call() {
    return repository.socketErrors();
  }
}

