import 'package:fpdart/fpdart.dart';
import 'package:ride_app/core/params/carpool_detail_params.dart';
import 'package:ride_app/core/params/carpool_param.dart';
import 'package:ride_app/features/ride_history/domain/enitities/carpool_history_detail_entities.dart';
import 'package:ride_app/features/ride_history/domain/enitities/carpool_history_entities.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/params/ride_history_detail_params.dart';
import '../../../../core/params/ride_history_param.dart';
import '../../domain/enitities/ride_history_detail_entities.dart';
import '../../domain/enitities/ride_history_entites.dart';
import '../../domain/repositories/ride_history_repository.dart';
import '../datasources/ride _history_datasource.dart';

abstract class RideHistoryRepositoryInternal implements RideHistoryRepository {}

class RideHistoryRepositoryImpl implements RideHistoryRepository {
  final RideHistoryRemoteDataSource _dataSource;

  RideHistoryRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, RideHistoryResponseEntity>> getRideHistory({
    required RideHistoryRequestParams params,
  }) async {
    final response = await _dataSource.getRideHistory(params: params);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (data) => Right(data),
    );
  }

  @override
  Future<Either<Failure, RideDetailResponseEntity>> getRideDetail({
    required RideHistoryDetailParams params,
  }) async {
    final response = await _dataSource.getRideDetail(params: params);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (data) => Right(data),
    );
  }

  @override
  Future<Either<Failure, CarpoolHistoryEntity>> getCarpoolHistory({
    required CarpoolParam params,
  }) async {
    final response = await _dataSource.getCarpoolHistory(params: params);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (data) => Right(data),
    );
  }

  @override
  Future<Either<Failure, CarpoolEntity>> getCarpoolDetail({
    required CarpoolDetailParams params,
  }) async {
    final response = await _dataSource.getCarpoolDetail(params: params);
    return response.fold(
      (failure) => Left(ServerFailure(message: failure.message)),
      (data) => Right(data),
    );
  }

 
}
