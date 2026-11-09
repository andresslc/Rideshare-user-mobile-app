import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/features/card/domain/repositories/card_repositories.dart';
import 'package:ride_app/shared/entities/card_entity.dart';

class CardListUsecase {
  final CardRepository cardListRepo;

  CardListUsecase(this.cardListRepo);

  Future<Either<Failure, BankCardsResponseEntity>> call() {
    return cardListRepo.getCards();
  }
}

