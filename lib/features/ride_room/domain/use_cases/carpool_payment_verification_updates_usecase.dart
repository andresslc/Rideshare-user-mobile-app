import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/ride_room/domain/entities/payment_verification_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class CarpoolPaymentVerificationUpdatesUseCase {
  final RideSocketRepository repository;

  CarpoolPaymentVerificationUpdatesUseCase(this.repository);

  Stream<Either<Failure, PaymentVerificationEntity>> call() {
    return repository.carpoolPaymentVerificationUpdates();
  }
}

