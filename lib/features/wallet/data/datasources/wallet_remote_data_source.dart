import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/extensions/string_extension.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/api_response_model.dart';
import '../../../../shared/models/card_model.dart';
import '../models/add_funds_result_model.dart';
import '../models/transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<
    Either<
      Failure,
      ({
        double balance,
        double rewardedBalance,
        double totalBalance,
        List<TransactionModel> transactions,
        Pagination? pagination,
      })
    >
  >
  getTransactionHistory({int page = 1, int limit = 10, String? type});

  Future<Either<Failure, AddFundsResultModel>> addFunds({
    required double amount,
    required String cardId,
  });

  Future<Either<Failure, List<BankCardModel>>> getCards();
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final ApiService _apiService = locator<ApiService>();

  @override
  Future<
    Either<
      Failure,
      ({
        double balance,
        double rewardedBalance,
        double totalBalance,
        List<TransactionModel> transactions,
        Pagination? pagination,
      })
    >
  >
  getTransactionHistory({int page = 1, int limit = 20, String? type}) async {
    return handleNetworkError(() async {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'limit': limit,
      };
      if (type != null && type != 'all') {
        queryParameters['type'] = type.capitalised;
      }

      final response = await _apiService.get(
        ApiEndpoints.transactionHistory,
        queryParameters: queryParameters,
      );

      final apiResponse = ApiResponse.fromMap(response.data);

      if (apiResponse.success) {
        final data = apiResponse.data as Map<String, dynamic>;
        final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        final rewardedBalance =
            (data['rewardedBalance'] as num?)?.toDouble() ?? 0.0;
        final totalBalance =
            (data['totalBalance'] as num?)?.toDouble() ??
            (balance + rewardedBalance);
        final transactionsJson = data['transactions'] as List<dynamic>? ?? [];
        final transactions = transactionsJson
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        return (
          balance: balance,
          rewardedBalance: rewardedBalance,
          totalBalance: totalBalance,
          transactions: transactions,
          pagination: apiResponse.pagination,
        );
      } else {
        throw Exception(
          apiResponse.message ?? 'Failed to fetch transaction history',
        );
      }
    });
  }

  @override
  Future<Either<Failure, AddFundsResultModel>> addFunds({
    required double amount,
    required String cardId,
  }) async {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.topUpWallet,
        data: {'amount': amount, 'cardId': cardId},
      );
      final apiResponse = ApiResponse.fromMap(response.data);
      final result = AddFundsResultModel.fromApiResponse(apiResponse);

      if (result.requiresAction && (result.clientSecret?.isEmpty ?? true)) {
        throw Exception('3D Secure required but clientSecret is missing.');
      }

      return result;
    });
  }

  @override
  Future<Either<Failure, List<BankCardModel>>> getCards() async {
    return handleNetworkError(() async {
      final response = await _apiService.get(ApiEndpoints.cardsList);
      final apiResponse = ApiResponse.fromMap(response.data);
      if (apiResponse.success) {
        final data = apiResponse.data as Map<String, dynamic>;
        final cardsJson = data['cards'] as List<dynamic>;
        return cardsJson.map((json) => BankCardModel.fromJson(json)).toList();
      } else {
        throw Exception(apiResponse.message ?? 'Failed to fetch cards');
      }
    });
  }
}
