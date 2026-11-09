
import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/card_params.dart';
import 'package:ride_app/features/card/domain/repositories/card_repositories.dart';
import 'package:ride_app/shared/entities/card_entity.dart';

class AddCardUsecase {
  final CardRepository addCardRepo;

  AddCardUsecase(this.addCardRepo);

  Future<Either<Failure, BankCardEntity>> call(AddCardParams params) {
    return addCardRepo.sendCardToBackend(params);
  }
}

