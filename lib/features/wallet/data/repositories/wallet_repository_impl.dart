import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/entities/card_entity.dart';
import '../../../../shared/models/api_response_model.dart';
import '../../domain/entities/add_funds_result_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;

  WalletRepositoryImpl(this._remoteDataSource);

  @override
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
  getTransactionHistory({int page = 1, int limit = 20, String? type}) async {
    return _remoteDataSource.getTransactionHistory(
      page: page,
      limit: limit,
      type: type,
    );
  }

  @override
  Future<Either<Failure, AddFundsResultEntity>> addFunds({
    required double amount,
    required String cardId,
  }) async {
    return _remoteDataSource.addFunds(amount: amount, cardId: cardId);
  }

  @override
  Future<Either<Failure, List<BankCardEntity>>> getCards() async {
    final result = await _remoteDataSource.getCards();
    return result.fold(
      (failure) => Left(failure),
      (cards) => Right(cards.map((e) => e.toEntity()).toList()),
    );
  }
}

