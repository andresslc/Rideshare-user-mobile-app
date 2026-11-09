import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/errors/failure.dart';
import 'package:ride_app/core/params/find_carpool_ride_params.dart';
import 'package:ride_app/features/ride_room/data/datasources/carpool_ride_data_source.dart';
import 'package:ride_app/features/ride_room/domain/entities/carpool_ride_response_entity.dart';
import 'package:ride_app/features/ride_room/domain/repositories/carpool_ride_repository.dart';

class CarpoolRideRepositoryImpl implements CarpoolRideRepository {
  final CarpoolRideDataSource dataSource;

  CarpoolRideRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, CarpoolRideEntity>> getCarpoolRideById(
    String rideId,
  ) async {
    final response = await dataSource.getCarpoolRideById(rideId);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }

  @override
  Future<Either<Failure, CarpoolRideResponseEntity>> findCarpoolRidesByAPI(
    FindCarpoolRideParams params,
  ) async {
    final response = await dataSource.findCarpoolRidesByAPI(params);
    return response.fold((failure) => Left(failure), (data) => Right(data));
  }
}
