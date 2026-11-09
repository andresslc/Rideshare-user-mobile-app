import 'dart:developer';

import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/fare_calculator_params.dart';
import 'package:ride_app/features/ride_room/data/datasources/ride_fare_remote_data_source.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_fare_quote_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_fare_repository.dart';

class RideFareRepositoryImpl implements RideFareRepository {
  final RideFareRemoteDataSource _dataSource;

  RideFareRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, RideFareQuoteEntity>> calculateFare(
    FareCalculatorParams params,
  ) async {
    int attempts = 0;
    const int maxAttempts = 4; // Initial attempt + 3 retries

    while (attempts < maxAttempts) {
      attempts++;
      final result = await _dataSource.calculateFare(params);

      bool isSuccess = false;
      result.fold(
        (failure) {
          if (attempts < maxAttempts) {
            log('Fare calculation failed (attempt $attempts/$maxAttempts): ${failure.message}. Retrying...');
          }
        },
        (fareQuote) {
          final double fare = fareQuote.primaryFare;
          if (fare >= 1) {
            isSuccess = true;
          } else if (attempts < maxAttempts) {
            log('Fare calculation returned invalid fare $fare (attempt $attempts/$maxAttempts). Retrying...');
          }
        },
      );

      if (isSuccess) {
        return result;
      }

      if (attempts < maxAttempts) {
        // Wait before retrying (1.5s, 3s, 4.5s)
        await Future.delayed(Duration(milliseconds: attempts * 1500));
      } else {
        // If we reached max attempts, return the last result
        return result;
      }
    }

    return const Left(ServerFailure(message: 'Fare calculation failed after retries'));
  }
}
