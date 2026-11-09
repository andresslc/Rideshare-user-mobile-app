import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/card_params.dart';
import '../../../../shared/models/api_response_model.dart';
import '../entities/transaction_entity.dart';
import '../repositories/wallet_repository.dart';

class GetTransactionHistoryUseCase {
  final WalletRepository repository;

  GetTransactionHistoryUseCase(this.repository);

  Future<
    Either<
      Failure,
      ({
        double balance,
        double rewardedBalance,
        double totalBalance,
        List<TransactionEntity> transactions,
        Pagination? pagination,
      })
    >
  >
  call(TransactionParams params) async {
    return repository.getTransactionHistory(
      page: params.page,
      type: params.type,
    );
  }
}

