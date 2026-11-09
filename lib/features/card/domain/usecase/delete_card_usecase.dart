import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/card/domain/repositories/card_repositories.dart';
import 'package:ride_app/shared/entities/card_entity.dart';

class DeleteCardUsecase {
  final CardRepository deleteCardRepo;

  DeleteCardUsecase(this.deleteCardRepo);

  Future<Either<Failure, BankCardEntity>> call(String params) {
    return deleteCardRepo.deleteCard(params);
  }
}

