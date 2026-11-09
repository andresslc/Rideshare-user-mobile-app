import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_upgrade_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class RideUpgradeOfferUpdatesUseCase {
  final RideSocketRepository repository;

  RideUpgradeOfferUpdatesUseCase(this.repository);

  Stream<Either<Failure, RideUpgradeOfferEntity>> call() {
    return repository.rideUpgradeOfferUpdates();
  }
}

class RideUpgradeResultUpdatesUseCase {
  final RideSocketRepository repository;

  RideUpgradeResultUpdatesUseCase(this.repository);

  Stream<Either<Failure, RideUpgradeResultEntity>> call() {
    return repository.rideUpgradeResultUpdates();
  }
}

class DecideRideUpgradeUseCase {
  final RideSocketRepository repository;

  DecideRideUpgradeUseCase(this.repository);

  Future<Either<Failure, RideUpgradeDecisionEntity>> call({
    required String rideId,
    required RideUpgradeDecision decision,
  }) {
    return repository.decideUpgrade(rideId: rideId, decision: decision);
  }
}
