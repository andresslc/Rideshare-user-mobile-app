import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/entities/card_entity.dart';
import '../repositories/wallet_repository.dart';

class GetCardsUseCase {
  final WalletRepository repository;

  GetCardsUseCase(this.repository);

  Future<Either<Failure, List<BankCardEntity>>> call() async {
    return repository.getCards();
  }
}

