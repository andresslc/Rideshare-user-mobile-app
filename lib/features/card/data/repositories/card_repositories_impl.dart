import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/card_params.dart';
import 'package:ride_app/features/card/data/datasources/card_datascource.dart';
import 'package:ride_app/features/card/domain/repositories/card_repositories.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/entities/card_entity.dart';

abstract class CardRepositoryInternal implements CardRepository {}

class CardRepositoryImpl implements CardRepositoryInternal {
  final CardDatasource dataSource;

  CardRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, BankCardEntity>> sendCardToBackend(
    AddCardParams params,
  ) async {
    final addCard = await dataSource.addBankCard(params);

    return addCard.fold(
      (left) => Left(ServerFailure(message: left.message)),
      (right) => Right(right),
    );
  }

  @override
  Future<Either<Failure, BankCardsResponseEntity>> getCards() async {
    final cardListing = await dataSource.getCards();

    return cardListing.fold(
      (left) => Left(ServerFailure(message: left.message)),
      (right) => Right(right),
    );
  }

  @override
  Future<Either<Failure, BankCardEntity>> setDefaultCard(String cardId) async {
    final setCard = await dataSource.setDefaultCard(cardId);

    return setCard.fold(
      (left) => Left(ServerFailure(message: left.message)),
      (right) => Right(right),
    );
  }

  @override
  Future<Either<Failure, BankCardEntity>> deleteCard(String cardId) async {
    final deleteCard = await dataSource.deleteCard(cardId);

    return deleteCard.fold(
      (left) => Left(ServerFailure(message: left.message)),
      (right) => Right(right),
    );
  }
}

