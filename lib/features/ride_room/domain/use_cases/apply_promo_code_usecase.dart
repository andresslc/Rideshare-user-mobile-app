import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/apply_promo_code_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/apply_promo_code_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_socket_repository.dart';

class ApplyPromoCodeUseCase {
  final RideSocketRepository repository;

  ApplyPromoCodeUseCase(this.repository);

  Future<Either<Failure, PromoCodeEntity>> call(
    ApplyPromoCodeParams params,
  ) async {
    final String normalizedCode = params.code.trim();
    if (normalizedCode.isEmpty) {
      final failure = const ServerFailure(
        message: 'Please enter a promo code.',
      );
      // state = AsyncData(
      //   value.copyWith(
      //     promoErrorMessage: failure.message,
      //     resetPromo: true,
      //     isApplyingPromoCode: false,
      //   ),
      // );
      return Left(failure);
    }

    return repository.applyPromoCode(params);
  }
}
