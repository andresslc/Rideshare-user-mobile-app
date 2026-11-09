import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/card/domain/repositories/card_repositories.dart';
import 'package:ride_app/shared/entities/card_entity.dart';

class SetDefaultCardUsecase {
  final CardRepository setDefaultCardRepo;

  SetDefaultCardUsecase(this.setDefaultCardRepo);

  Future<Either<Failure, BankCardEntity>> call(String params) {
    return setDefaultCardRepo.setDefaultCard(params);
  }
}

