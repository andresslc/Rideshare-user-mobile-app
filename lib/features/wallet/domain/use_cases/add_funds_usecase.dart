import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/card_params.dart';
import '../entities/add_funds_result_entity.dart';
import '../repositories/wallet_repository.dart';

class AddFundsUseCase {
  final WalletRepository repository;

  AddFundsUseCase(this.repository);

  Future<Either<Failure, AddFundsResultEntity>> call(
    AddFundParams params,
  ) async {
    return repository.addFunds(
      amount: params.amount.toDouble(),
      cardId: params.paymentMethodId,
    );
  }
}

