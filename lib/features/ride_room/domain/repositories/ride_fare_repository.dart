import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/fare_calculator_params.dart';
import 'package:ride_app/features/ride_room/domain/entities/ride_fare_quote_entity.dart';

abstract class RideFareRepository {
  Future<Either<Failure, RideFareQuoteEntity>> calculateFare(
    FareCalculatorParams params,
  );
}
