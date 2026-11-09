import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure.dart';
import '../../../../shared/entities/card_entity.dart';
import '../../../../shared/models/api_response_model.dart';
import '../entities/add_funds_result_entity.dart';
import '../entities/transaction_entity.dart';

abstract class WalletRepository {
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
  getTransactionHistory({int page = 1, int limit = 20, String? type});

  Future<Either<Failure, AddFundsResultEntity>> addFunds({
    required double amount,
    required String cardId,
  });

  Future<Either<Failure, List<BankCardEntity>>> getCards();
}

