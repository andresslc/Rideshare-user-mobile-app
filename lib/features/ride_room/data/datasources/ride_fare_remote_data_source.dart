import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/constants/api_endpoints.dart';
import 'package:ride_app/core/di/service_locator.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/errors/network_error_handler.dart';
import 'package:ride_app/core/params/fare_calculator_params.dart';
import 'package:ride_app/core/services/api_service.dart';
import 'package:ride_app/features/ride_room/data/models/ride_fare_quote_model.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_fare_quote_entity.dart';
import 'package:ride_app/shared/models/api_response_model.dart';

abstract class RideFareRemoteDataSource {
  Future<Either<Failure, RideFareQuoteEntity>> calculateFare(
    FareCalculatorParams params,
  );
}

class RideFareRemoteDataSourceImpl implements RideFareRemoteDataSource {
  final ApiService _apiService = locator<ApiService>();

  @override
  Future<Either<Failure, RideFareQuoteEntity>> calculateFare(
    FareCalculatorParams params,
  ) async {
    return handleNetworkError(() async {
      final response = await _apiService.post(
        ApiEndpoints.fareCalculator,
        data: params.toJson(),
      );
      final dynamic payload = ApiResponse.fromMap(response.data).data;
      final quote = RideFareQuoteModel.fromJson(_asMap(payload));
      if (!quote.hasAnyFare) {
        throw Exception('Fare amount missing in response');
      }
      return quote;
    });
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

