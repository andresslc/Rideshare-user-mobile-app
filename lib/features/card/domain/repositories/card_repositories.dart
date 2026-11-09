
import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/card_params.dart';
import 'package:ride_app/shared/entities/card_entity.dart';

abstract class CardRepository {
  Future<Either<Failure, BankCardEntity>> sendCardToBackend(
    AddCardParams params,
  );
  Future<Either<Failure, BankCardsResponseEntity>> getCards();
  Future<Either<Failure, BankCardEntity>> setDefaultCard(String cardId);
  Future<Either<Failure, BankCardEntity>> deleteCard(String cardId);
}

