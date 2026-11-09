import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

import '../entities/payment_verification_entity.dart';

class RidePaymentUpdatesUseCase {
  final RideSocketRepository repository;

  RidePaymentUpdatesUseCase(this.repository);

  Stream<Either<Failure, PaymentVerificationEntity>> call() {
    return repository.ridePaymentVerificationUpdates();
  }
}

