import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_resume_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolResumeUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolResumeUpdatesUseCase(this.repository);

  Stream<Either<Failure, CarpoolResumeEntity>> call() {
    return repository.carpoolResumeUpdates();
  }
}

