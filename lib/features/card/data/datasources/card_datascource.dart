import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/card_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/shared/models/card_model.dart';

import '../../../../core/errors/failure.dart';

/// ===============================
/// ABSTRACT DATASOURCE
/// ===============================
abstract class CardDatasource {
  /// Add new bank card
  Future<Either<Failure, BankCardModel>> addBankCard(AddCardParams params);

  /// Set default card
  Future<Either<Failure, BankCardModel>> setDefaultCard(String cardId);

  /// Delete a saved card
  Future<Either<Failure, BankCardModel>> deleteCard(String cardId);

  /// Get all saved cards
  Future<Either<Failure, BankCardsResponseModel>> getCards();
}

/// ===============================
/// IMPLEMENTATION
/// ===============================
class CardDatasourceImpl implements CardDatasource {
  final ApiService apiService = locator<ApiService>();

  /// ---------------------------------
  /// ADD BANK CARD
  /// ---------------------------------
  @override
  Future<Either<Failure, BankCardModel>> addBankCard(AddCardParams params) {
    return handleNetworkError(() async {
      final Response res = await apiService.post(
        ApiEndpoints.addCard,
        data: {'pmId': params.paymentMethodId},
      );

      final cardJson = res.data['data']['card'] as Map<String, dynamic>;
      return BankCardModel.fromJson(cardJson);
    });
  }

  /// ---------------------------------
  /// GET ALL SAVED CARDS
  /// ---------------------------------
  @override
  Future<Either<Failure, BankCardsResponseModel>> getCards() {
    return handleNetworkError(() async {
      final response = await apiService.get(ApiEndpoints.cardsList);
      return BankCardsResponseModel.fromJson(response.data);
    });
  }

  /// ---------------------------------
  /// SET DEFAULT CARD
  /// ---------------------------------
  @override
  Future<Either<Failure, BankCardModel>> setDefaultCard(String cardId) {
    return handleNetworkError(() async {
      final String url = '${ApiEndpoints.setDefaultCard}$cardId/set-as-default';
      final Response res = await apiService.post(url, data: {'cardId': cardId});
      return BankCardModel.fromJson(res.data);
    });
  }

  /// ---------------------------------
  /// DELETE CARD
  /// ---------------------------------
  @override
  Future<Either<Failure, BankCardModel>> deleteCard(String cardId) {
    return handleNetworkError(() async {
      final String url = '${ApiEndpoints.deleteCard}$cardId/remove';
      final Response res = await apiService.post(url);
      final BankCardModel deletedCard = BankCardModel.fromJson(res.data);
      return deletedCard;
    });
  }
}

