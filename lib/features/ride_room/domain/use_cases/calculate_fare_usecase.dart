import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/fare_calculator_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_fare_quote_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/ride_fare_repository.dart';

class CalculateFareUseCase {
  final RideFareRepository repository;

  CalculateFareUseCase(this.repository);

  Future<Either<Failure, RideFareQuoteEntity>> call(
    FareCalculatorParams params,
  ) async {
    return repository.calculateFare(params);
  }
}

